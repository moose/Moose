package Moose::Exception::Role::TypeConstraint;

use Moose::Role;
use Moose::Util qw/throw_exception/;
use Moose::Util::TypeConstraints qw/find_type_constraint/;

has 'type' => (
    is        => 'rw',
    isa       => 'Moose::Meta::TypeConstraint',
    lazy      => 1,
    builder   => '_build_type',
    predicate => 'is_type_set',
);

has 'type_name' => (
    is        => 'ro',
    isa       => 'Str',
    lazy      => 1,
    builder   => '_build_type_name',
    predicate => 'is_type_name_set',
);

sub _build_type {
    my $self = $_[0];
    Moose::Util::TypeConstraints::find_type_constraint( $self->type_name );    
}

sub _build_type_name {
    my $self = $_[0];
    $self->type->name;
}

after "BUILD" => sub {
    my $self = $_[0];
    if( !( $self->is_type_name_set) && !( $self->is_type_set) )
    {
	throw_exception("NeitherTypeNorTypeNameIsGiven");
    }

    if( $self->is_type_name_set &&
	$self->is_type_set &&
	( $self->type->name ne $self->type_name ) )
    {
        throw_exception( TypeNamesDoNotMatch => type_name => $self->type_name,
                                                type      => $self->type,
                       );
    }
};

1;
