
package Moose::Role;

use strict;
use warnings;

use Scalar::Util 'blessed';
use Carp         'croak';

use Data::OptList;
use Sub::Exporter;

our $VERSION   = '0.64';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose       ();
use Moose::Util ();

use Moose::Meta::Role;
use Moose::Util::TypeConstraints;

sub extends {
    croak "Roles do not currently support 'extends'";
}

sub with {
    Moose::Util::apply_all_roles( Moose::Meta::Role->initialize(shift), @_ );
}

sub requires {
    my $meta = Moose::Meta::Role->initialize(shift);
    croak "Must specify at least one method" unless @_;
    $meta->add_required_methods(@_);
}

sub excludes {
    my $meta = Moose::Meta::Role->initialize(shift);
    croak "Must specify at least one role" unless @_;
    $meta->add_excluded_roles(@_);
}

sub has {
    my $meta = Moose::Meta::Role->initialize(shift);
    my $name = shift;
    croak 'Usage: has \'name\' => ( key => value, ... )' if @_ == 1;
    my %options = @_;
    my $attrs = ( ref($name) eq 'ARRAY' ) ? $name : [ ($name) ];
    $meta->add_attribute( $_, %options ) for @$attrs;
}

sub before {
    my $meta = Moose::Meta::Role->initialize(shift);
    my $code = pop @_;

    for (@_) {
        croak "Roles do not currently support "
            . ref($_)
            . " references for before method modifiers"
            if ref $_;
        $meta->add_before_method_modifier( $_, $code );
    }
}

sub after {
    my $meta = Moose::Meta::Role->initialize(shift);

    my $code = pop @_;
    for (@_) {
        croak "Roles do not currently support "
            . ref($_)
            . " references for after method modifiers"
            if ref $_;
        $meta->add_after_method_modifier( $_, $code );
    }
}

sub around {
    my $meta = Moose::Meta::Role->initialize(shift);
    my $code = pop @_;
    for (@_) {
        croak "Roles do not currently support "
            . ref($_)
            . " references for around method modifiers"
            if ref $_;
        $meta->add_around_method_modifier( $_, $code );
    }
}

# see Moose.pm for discussion
sub super {
    return unless $Moose::SUPER_BODY;
    $Moose::SUPER_BODY->(@Moose::SUPER_ARGS);
}

sub override {
    my $meta = Moose::Meta::Role->initialize(shift);
    my ( $name, $code ) = @_;
    $meta->add_override_method_modifier( $name, $code );
}

sub inner {
    croak "Roles cannot support 'inner'";
}

sub augment {
    croak "Roles cannot support 'augment'";
}

my $exporter = Moose::Exporter->setup_import_methods(
    with_caller => [
        qw( with requires excludes has before after around override make_immutable )
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

    my $role = $args{for_class}
        or Moose->throw_error("Cannot call init_meta without specifying a for_class");

    my $metaclass = $args{metaclass} || "Moose::Meta::Role";

    # make a subtype for each Moose class
    role_type $role unless find_type_constraint($role);

    # FIXME copy from Moose.pm
    my $meta;
    if ($role->can('meta')) {
        $meta = $role->meta();
        (blessed($meta) && $meta->isa('Moose::Meta::Role'))
            || Moose->throw_error("You already have a &meta function, but it does not return a Moose::Meta::Role");
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

Role support in Moose is pretty solid at this point. However, the best
documentation is still the the test suite. It is fairly safe to assume Perl 6
style behavior and then either refer to the test suite, or ask questions on
#moose if something doesn't quite do what you expect.

We are planning writing some more documentation in the near future, but nothing
is ready yet, sorry.

=head1 EXPORTED FUNCTIONS

Moose::Role currently supports all of the functions that L<Moose> exports, but
differs slightly in how some items are handled (see L<CAVEATS> below for
details).

Moose::Role also offers two role-specific keyword exports:

=over 4

=item B<requires (@method_names)>

Roles can require that certain methods are implemented by any class which
C<does> the role.

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

=item *

The C<requires> keyword currently only works with actual methods. A method
modifier (before/around/after and override) will not count as a fufillment
of the requirement, and neither will an autogenerated accessor for an attribute.

It is likely that attribute accessors will eventually be allowed to fufill those
requirements, or we will introduce a C<requires_attr> keyword of some kind
instead. This decision has not yet been finalized.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

Christian Hansen E<lt>chansen@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
