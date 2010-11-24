package Moose::Util::MetaRole;

use strict;
use warnings;
use Scalar::Util 'blessed';

our $VERSION   = '1.21';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use List::MoreUtils qw( all );
use List::Util qw( first );
use Moose::Deprecated;

sub apply_metaclass_roles {
    Moose::Deprecated::deprecated(
        feature => 'pre-0.94 MetaRole API',
        message =>
            'The old Moose::Util::MetaRole API (before version 0.94) has been deprecated'
    );

    goto &apply_metaroles;
}

sub apply_metaroles {
    my %args = @_;

    _fixup_old_style_args(\%args);

    my $for
        = blessed $args{for}
        ? $args{for}
        : Class::MOP::class_of( $args{for} );

    if ( $for->isa('Moose::Meta::Role') ) {
        return _make_new_metaclass( $for, $args{role_metaroles}, 'role' );
    }
    else {
        return _make_new_metaclass( $for, $args{class_metaroles}, 'class' );
    }
}

sub _fixup_old_style_args {
    my $args = shift;

    return if $args->{class_metaroles} || $args->{role_metaroles};

    Moose::Deprecated::deprecated(
        feature => 'pre-0.94 MetaRole API',
        message =>
            'The old Moose::Util::MetaRole API (before version 0.94) has been deprecated'
    );

    $args->{for} = delete $args->{for_class}
        if exists $args->{for_class};

    my @old_keys = qw(
        attribute_metaclass_roles
        method_metaclass_roles
        wrapped_method_metaclass_roles
        instance_metaclass_roles
        constructor_class_roles
        destructor_class_roles
        error_class_roles

        application_to_class_class_roles
        application_to_role_class_roles
        application_to_instance_class_roles
        application_role_summation_class_roles
    );

    my $for
        = blessed $args->{for}
        ? $args->{for}
        : Class::MOP::class_of( $args->{for} );

    my $top_key;
    if ( $for->isa('Moose::Meta::Class') ) {
        $top_key = 'class_metaroles';

        $args->{class_metaroles}{class} = delete $args->{metaclass_roles}
            if exists $args->{metaclass_roles};
    }
    else {
        $top_key = 'role_metaroles';

        $args->{role_metaroles}{role} = delete $args->{metaclass_roles}
            if exists $args->{metaclass_roles};
    }

    for my $old_key (@old_keys) {
        my ($new_key) = $old_key =~ /^(.+)_(?:class|metaclass)_roles$/;

        $args->{$top_key}{$new_key} = delete $args->{$old_key}
            if exists $args->{$old_key};
    }

    return;
}

sub _make_new_metaclass {
    my $for     = shift;
    my $roles   = shift;
    my $primary = shift;

    return $for unless keys %{$roles};

    my $new_metaclass
        = exists $roles->{$primary}
        ? _make_new_class( ref $for, $roles->{$primary} )
        : blessed $for;

    my %classes;

    for my $key ( grep { $_ ne $primary } keys %{$roles} ) {
        my $attr = first {$_}
            map { $for->meta->find_attribute_by_name($_) } (
            $key . '_metaclass',
            $key . '_class'
        );

        my $reader = $attr->get_read_method;

        $classes{ $attr->init_arg }
            = _make_new_class( $for->$reader(), $roles->{$key} );
    }

    my $new_meta = $new_metaclass->reinitialize( $for, %classes );

    return $new_meta;
}

sub apply_base_class_roles {
    my %args = @_;

    my $for = $args{for} || $args{for_class};

    my $meta = Class::MOP::class_of($for);

    my $new_base = _make_new_class(
        $for,
        $args{roles},
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

    my $meta = Class::MOP::Class->initialize($existing_class);

    return $existing_class
        if $meta->can('does_role') && all  { $meta->does_role($_) }
                                      grep { !ref $_ } @{$roles};

    return Moose::Meta::Class->create_anon_class(
        superclasses => $superclasses,
        roles        => $roles,
        cache        => 1,
    )->name();
}

1;

__END__

=head1 NAME

Moose::Util::MetaRole - Apply roles to any metaclass, as well as the object base class

=head1 SYNOPSIS

  package MyApp::Moose;

  use Moose ();
  use Moose::Exporter;
  use Moose::Util::MetaRole;

  use MyApp::Role::Meta::Class;
  use MyApp::Role::Meta::Method::Constructor;
  use MyApp::Role::Object;

  Moose::Exporter->setup_import_methods( also => 'Moose' );

  sub init_meta {
      shift;
      my %args = @_;

      Moose->init_meta(%args);

      Moose::Util::MetaRole::apply_metaroles(
          for             => $args{for_class},
          class_metaroles => {
              class => => ['MyApp::Role::Meta::Class'],
              constructor => ['MyApp::Role::Meta::Method::Constructor'],
          },
      );

      Moose::Util::MetaRole::apply_base_class_roles(
          for   => $args{for_class},
          roles => ['MyApp::Role::Object'],
      );

      return $args{for_class}->meta();
  }

=head1 DESCRIPTION

This utility module is designed to help authors of Moose extensions
write extensions that are able to cooperate with other Moose
extensions. To do this, you must write your extensions as roles, which
can then be dynamically applied to the caller's metaclasses.

This module makes sure to preserve any existing superclasses and roles
already set for the meta objects, which means that any number of
extensions can apply roles in any order.

=head1 USAGE

The easiest way to use this module is through L<Moose::Exporter>, which can
generate the appropriate C<init_meta> method for you, and make sure it is
called when imported.

=head1 FUNCTIONS

This module provides two functions.

=head2 apply_metaroles( ... )

This function will apply roles to one or more metaclasses for the specified
class. It will return a new metaclass object for the class or role passed in
the "for" parameter.

It accepts the following parameters:

=over 4

=item * for => $name

This specifies the class or for which to alter the meta classes. This can be a
package name, or an appropriate meta-object (a L<Moose::Meta::Class> or
L<Moose::Meta::Role>).

=item * class_metaroles => \%roles

This is a hash reference specifying which metaroles will be applied to the
class metaclass and its contained metaclasses and helper classes.

Each key should in turn point to an array reference of role names.

It accepts the following keys:

=over 8

=item class

=item attribute

=item method

=item wrapped_method

=item instance

=item constructor

=item destructor

=item error

=back

=item * role_metaroles => \%roles

This is a hash reference specifying which metaroles will be applied to the
role metaclass and its contained metaclasses and helper classes.

It accepts the following keys:

=over 8

=item role

=item attribute

=item method

=item required_method

=item conflicting_method

=item application_to_class

=item application_to_role

=item application_to_instance

=item application_role_summation

=back

=back

=head2 apply_base_class_roles( for => $class, roles => \@roles )

This function will apply the specified roles to the object's base class.

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHOR

Dave Rolsky E<lt>autarch@urth.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009-2010 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
