package Moose::Meta::Attribute::Trait::InRole;

use Moose::Role;

use Carp 'confess';
use Scalar::Util 'blessed', 'weaken';

our $VERSION   = '0.93';
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Meta::Method::Stub;

around attach_to_class => sub {
    shift;
    my ( $self, $class ) = @_;

    ( blessed($class) && $class->isa('Moose::Meta::Role') )
        || confess
        "You must pass a Moose::Meta::Role instance (or a subclass)";

    weaken( $self->{'associated_class'} = $class );
};

around 'accessor_metaclass' => sub {
    return 'Moose::Meta::Method::Stub';
};

around 'delegation_metaclass' => sub {
    return 'Moose::Meta::Method::Stub';
};

around _check_associated_methods => sub { };

around clone => sub {
    my $orig = shift;
    my $self = shift;

    my $meta = $self->meta;

    my @supers = $meta->superclasses();
    my @traits_to_keep = grep { $_ ne __PACKAGE__ }
        map  { $_->name }
        grep { !$_->isa('Moose::Meta::Role::Composite') }
        $meta->calculate_all_roles;

    my $new_class;

    if ( @traits_to_keep || @supers > 1 ) {
        my $anon_class = Moose::Meta::Class->create_anon_class(
            superclasses => \@supers,
            roles        => \@traits_to_keep,
            cache        => 1,
        );

        $new_class = $anon_class->name;
    }
    else {
        $new_class = $supers[0];
    }

    return $self->$orig( @_, metaclass => $new_class );
};

no Moose::Role;

1;
