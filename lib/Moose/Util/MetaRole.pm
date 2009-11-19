package Moose::Util::MetaRole;

use strict;
use warnings;
use Scalar::Util 'blessed';

our $VERSION   = '0.93';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use List::MoreUtils qw( all );

my @Classes = qw( constructor_class destructor_class error_class );

sub apply_metaclass_roles {
    my %options = @_;

    my $for = blessed $options{for_class}
        ? $options{for_class}
        : Class::MOP::class_of($options{for_class});

    my %old_classes = map { $_ => $for->$_ }
                      grep { $for->can($_) }
                      @Classes;

    my $meta = _make_new_metaclass( $for, \%options );

    for my $c ( grep { $meta->can($_) } @Classes ) {
        if ( $options{ $c . '_roles' } ) {
            my $class = _make_new_class(
                $meta->$c(),
                $options{ $c . '_roles' }
            );

            $meta->$c($class);
        }
        else {
            $meta->$c( $old_classes{$c} );
        }
    }

    return $meta;
}

sub _make_new_metaclass {
    my $for     = shift;
    my $options = shift;

    return $for
        unless grep { exists $options->{ $_ . '_roles' } }
            qw(
            metaclass
            attribute_metaclass
            method_metaclass
            wrapped_method_metaclass
            instance_metaclass
            application_to_class_class
            application_to_role_class
            application_to_instance_class
            application_role_summation_class
    );

    my $new_metaclass
        = _make_new_class( ref $for, $options->{metaclass_roles} );

    # This could get called for a Moose::Meta::Role as well as a Moose::Meta::Class
    my %classes = map {
        $_ => _make_new_class( $for->$_(), $options->{ $_ . '_roles' } )
        }
        grep { $for->can($_) }
        qw(
        attribute_metaclass
        method_metaclass
        wrapped_method_metaclass
        instance_metaclass
        application_to_class_class
        application_to_role_class
        application_to_instance_class
        application_role_summation_class
    );

    return $new_metaclass->reinitialize( $for, %classes );
}

sub apply_base_class_roles {
    my %options = @_;

    my $for = $options{for_class};

    my $meta = Class::MOP::class_of($for);

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
      my %options = @_;

      Moose->init_meta(%options);

      Moose::Util::MetaRole::apply_metaclass_roles(
          for_class               => $options{for_class},
          metaclass_roles         => ['MyApp::Role::Meta::Class'],
          constructor_class_roles => ['MyApp::Role::Meta::Method::Constructor'],
      );

      Moose::Util::MetaRole::apply_base_class_roles(
          for_class => $options{for_class},
          roles     => ['MyApp::Role::Object'],
      );

      return $options{for_class}->meta();
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

B<It is very important that you only call this module's functions when
your module is imported by the caller>. The process of applying roles
to the metaclass reinitializes the metaclass object, which wipes out
any existing attributes already defined. However, as long as you do
this when your module is imported, the caller should not have any
attributes defined yet.

The easiest way to ensure that this happens is to use
L<Moose::Exporter>, which can generate the appropriate C<init_meta>
method for you, and make sure it is called when imported.

=head1 FUNCTIONS

This module provides two functions.

=head2 apply_metaclass_roles( ... )

This function will apply roles to one or more metaclasses for the
specified class. It accepts the following parameters:

=over 4

=item * for_class => $name

This specifies the class for which to alter the meta classes.

=item * metaclass_roles => \@roles

=item * attribute_metaclass_roles => \@roles

=item * method_metaclass_roles => \@roles

=item * wrapped_method_metaclass_roles => \@roles

=item * instance_metaclass_roles => \@roles

=item * constructor_class_roles => \@roles

=item * destructor_class_roles => \@roles

=item * application_to_class_class_roles => \@roles

=item * application_to_role_class_roles => \@roles

=item * application_to_instance_class_roles => \@roles

These parameter all specify one or more roles to be applied to the
specified metaclass. You can pass any or all of these parameters at
once.

=back

=head2 apply_base_class_roles( for_class => $class, roles => \@roles )

This function will apply the specified roles to the object's base class.

=head1 AUTHOR

Dave Rolsky E<lt>autarch@urth.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
