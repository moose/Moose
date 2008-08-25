package Moose::Util::MetaRole;

use strict;
use warnings;

use List::MoreUtils qw( all );

sub apply_metaclass_roles {
    my %options = @_;

    my $for = $options{for_class};

    my $meta = _make_new_metaclass( $for, \%options );

    for my $tor_class ( grep { $options{ $_ . '_roles' } }
        qw( constructor_class destructor_class ) ) {

        my $class = _make_new_class(
            $meta->$tor_class(),
            $options{ $tor_class . '_roles' }
        );

        $meta->$tor_class($class);
    }

    return $meta;
}

sub _make_new_metaclass {
    my $for     = shift;
    my $options = shift;

    return $for->meta()
        unless grep { exists $options->{ $_ . '_roles' } }
            qw(
            metaclass
            attribute_metaclass
            method_metaclass
            instance_metaclass
    );

    my $new_metaclass
        = _make_new_class( ref $for->meta(), $options->{metaclass_roles} );

    my $old_meta = $for->meta();

    Class::MOP::remove_metaclass_by_name($for);

    my %classes = map {
        $_ => _make_new_class( $old_meta->$_(), $options->{ $_ . '_roles' } )
        } qw(
        attribute_metaclass
        method_metaclass
        instance_metaclass
    );

    return $new_metaclass->reinitialize( $for, %classes );
}

sub apply_base_class_roles {
    my %options = @_;

    my $for = $options{for_class};

    my $meta = $for->meta();

    my $new_base = _make_new_class(
        $for,
        $options{roles},
        [ $meta->superclasses() ],
    );

    $meta->superclasses($new_base)
        if $new_base ne $meta->name();
}

sub _make_new_class {
    my $existing_class = shift;
    my $roles          = shift;
    my $superclasses   = shift || [$existing_class];

    return $existing_class unless $roles;

    my $meta = $existing_class->meta();

    return $existing_class
        if $meta->can('does_role') && all { $meta->does_role($_) } @{$roles};

    return Moose::Meta::Class->create_anon_class(
        superclasses => $superclasses,
        roles        => $roles,
        cache        => 1,
    )->name();
}

1;
