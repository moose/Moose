package Moose::Exception::Role::Role;

use Moose::Util 'throw_exception';
use Moose::Role;

has 'role' => (
    is        => 'rw',
    isa       => 'Moose::Meta::Role',
    lazy      => 1,
    builder   => '_build_role',
    predicate => 'is_role_set',
);

has 'role_name' => (
    is        => 'ro',
    isa       => 'Str',
    lazy      => 1,
    builder   => '_build_role_name',
    predicate => 'is_role_name_set',    
);


sub _build_role {
    my $self = $_[0];
    Class::MOP::class_of( $self->role_name );
}

sub _build_role_name {
    my $self = $_[0];
    $self->role->name;
}

after "BUILD" => sub {
    my $self = $_[0];
    if( !( $self->is_role_name_set) && !( $self->is_role_set) )
    {
	throw_exception("NeitherRoleNorRoleNameIsGiven");
    }

    if( $self->is_role_name_set &&
	$self->is_role_set &&
	( $self->role->name ne $self->role_name ) )
    {
        throw_exception( RoleNamesDoNotMatch => role_name => $self->role_name,
                                                role      => $self->role,
                       );
    }
};

1;
