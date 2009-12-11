package Moose::Role;
use strict;
use warnings;

use Scalar::Util 'blessed';
use Carp         'croak';

use Sub::Exporter;

our $VERSION   = '0.93';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose       ();
use Moose::Util ();

use Moose::Exporter;
use Moose::Meta::Role;
use Moose::Util::TypeConstraints;

sub extends {
    croak "Roles do not support 'extends' (you can use 'with' to specialize a role)";
}

sub with {
    Moose::Util::apply_all_roles( shift, @_ );
}

sub requires {
    my $meta = shift;
    croak "Must specify at least one method" unless @_;
    $meta->add_required_methods(@_);
}

sub excludes {
    my $meta = shift;
    croak "Must specify at least one role" unless @_;
    $meta->add_excluded_roles(@_);
}

sub has {
    my $meta = shift;
    my $name = shift;
    croak 'Usage: has \'name\' => ( key => value, ... )' if @_ == 1;
    my %options = ( definition_context => Moose::Util::_caller_info(), @_ );
    my $attrs = ( ref($name) eq 'ARRAY' ) ? $name : [ ($name) ];
    $meta->add_attribute( $_, %options ) for @$attrs;
}

sub _add_method_modifier {
    my $type = shift;
    my $meta = shift;
    my $code = pop @_;

    for (@_) {
        croak "Roles do not currently support "
            . ref($_)
            . " references for $type method modifiers"
            if ref $_;
        my $add_method = "add_${type}_method_modifier";
        $meta->$add_method( $_, $code );
    }
}

sub before { _add_method_modifier('before', @_) }

sub after  { _add_method_modifier('after',  @_) }

sub around { _add_method_modifier('around', @_) }

# see Moose.pm for discussion
sub super {
    return unless $Moose::SUPER_BODY;
    $Moose::SUPER_BODY->(@Moose::SUPER_ARGS);
}

sub override {
    my $meta = shift;
    my ( $name, $code ) = @_;
    $meta->add_override_method_modifier( $name, $code );
}

sub inner {
    croak "Roles cannot support 'inner'";
}

sub augment {
    croak "Roles cannot support 'augment'";
}

Moose::Exporter->setup_import_methods(
    with_meta => [
        qw( with requires excludes has before after around override )
    ],
    as_is => [
        qw( extends super inner augment ),
        \&Carp::confess,
        \&Scalar::Util::blessed,
    ],
);

sub init_meta {
    shift;
    my %args = @_;

    my $role = $args{for_class};

    unless ($role) {
        require Moose;
        Moose->throw_error("Cannot call init_meta without specifying a for_class");
    }

    my $metaclass = $args{metaclass} || "Moose::Meta::Role";

    # make a subtype for each Moose class
    role_type $role unless find_type_constraint($role);

    # FIXME copy from Moose.pm
    my $meta;
    if ($role->can('meta')) {
        $meta = $role->meta();

        unless ( blessed($meta) && $meta->isa('Moose::Meta::Role') ) {
            require Moose;
            Moose->throw_error("You already have a &meta function, but it does not return a Moose::Meta::Role");
        }
    }
    else {
        $meta = $metaclass->initialize($role);

        $meta->add_method(
            'meta' => sub {
                # re-initialize so it inherits properly
                $metaclass->initialize( ref($_[0]) || $_[0] );
            }
        );
    }

    return $meta;
}

1;

__END__

=pod

=head1 NAME

Moose::Role - The Moose Role

=head1 SYNOPSIS

  package Eq;
  use Moose::Role; # automatically turns on strict and warnings

  requires 'equal';

  sub no_equal {
      my ($self, $other) = @_;
      !$self->equal($other);
  }

  # ... then in your classes

  package Currency;
  use Moose; # automatically turns on strict and warnings

  with 'Eq';

  sub equal {
      my ($self, $other) = @_;
      $self->as_float == $other->as_float;
  }

=head1 DESCRIPTION

The concept of roles is documented in L<Moose::Manual::Roles>. This document
serves as API documentation.

=head1 EXPORTED FUNCTIONS

Moose::Role currently supports all of the functions that L<Moose> exports, but
differs slightly in how some items are handled (see L<CAVEATS> below for
details).

Moose::Role also offers two role-specific keyword exports:

=over 4

=item B<requires (@method_names)>

Roles can require that certain methods are implemented by any class which
C<does> the role.

Note that attribute accessors also count as methods for the purposes
of satisfying the requirements of a role.

=item B<excludes (@role_names)>

Roles can C<exclude> other roles, in effect saying "I can never be combined
with these C<@role_names>". This is a feature which should not be used
lightly.

=back

=head2 B<unimport>

Moose::Role offers a way to remove the keywords it exports, through the
C<unimport> method. You simply have to say C<no Moose::Role> at the bottom of
your code for this to work.

=head2 B<< Moose::Role->init_meta(for_class => $role, metaclass => $metaclass) >>

The C<init_meta> method sets up the metaclass object for the role
specified by C<for_class>. It also injects a a C<meta> accessor into
the role so you can get at this object.

The default metaclass is L<Moose::Meta::Role>. You can specify an
alternate metaclass with the C<metaclass> parameter.

=head1 METACLASS

When you use Moose::Role, you can specify which metaclass to use:

    use Moose::Role -metaclass => 'My::Meta::Role';

You can also specify traits which will be applied to your role metaclass:

    use Moose::Role -traits => 'My::Trait';

This is very similar to the attribute traits feature. When you do
this, your class's C<meta> object will have the specified traits
applied to it. See L<Moose/Metaclass and Trait Name Resolution> for more
details.

=head1 APPLYING ROLES

In addition to being applied to a class using the 'with' syntax (see
L<Moose::Manual::Roles>) and using the L<Moose::Util> 'apply_all_roles'
method, roles may also be applied to an instance of a class using
L<Moose::Util> 'apply_all_roles' or the role's metaclass:

   MyApp::Test::SomeRole->meta->apply( $instance );

Doing this creates a new, mutable, anonymous subclass, applies the role to that,
and reblesses. In a debugger, for example, you will see class names of the
form C< Class::MOP::Class::__ANON__::SERIAL::6 >, which means that doing a 'ref'
on your instance may not return what you expect. See L<Moose::Object> for 'DOES'.

Additional params may be added to the new instance by providing 'rebless_params'.
See L<Moose::Meta::Role::Application::ToInstance>.

=head1 CAVEATS

Role support has only a few caveats:

=over 4

=item *

Roles cannot use the C<extends> keyword; it will throw an exception for now.
The same is true of the C<augment> and C<inner> keywords (not sure those
really make sense for roles). All other Moose keywords will be I<deferred>
so that they can be applied to the consuming class.

=item *

Role composition does its best to B<not> be order-sensitive when it comes to
conflict resolution and requirements detection. However, it is order-sensitive
when it comes to method modifiers. All before/around/after modifiers are
included whenever a role is composed into a class, and then applied in the order
in which the roles are used. This also means that there is no conflict for
before/around/after modifiers.

In most cases, this will be a non-issue; however, it is something to keep in
mind when using method modifiers in a role. You should never assume any
ordering.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

Christian Hansen E<lt>chansen@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2009 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
