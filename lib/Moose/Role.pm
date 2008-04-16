
package Moose::Role;

use strict;
use warnings;

use Scalar::Util 'blessed';
use Carp         'confess';
use Sub::Name    'subname';

use Data::OptList;
use Sub::Exporter;

our $VERSION   = '0.08';
our $AUTHORITY = 'cpan:STEVAN';

use Moose       ();
use Moose::Util ();

use Moose::Meta::Role;
use Moose::Util::TypeConstraints;

{
    my ( $CALLER, %METAS );

    sub _find_meta {
        my $role = $CALLER;

        return $METAS{$role} if exists $METAS{$role};

        # make a subtype for each Moose class
        role_type $role unless find_type_constraint($role);

        my $meta;
        if ($role->can('meta')) {
            $meta = $role->meta();
            (blessed($meta) && $meta->isa('Moose::Meta::Role'))
                || confess "You already have a &meta function, but it does not return a Moose::Meta::Role";
        }
        else {
            $meta = Moose::Meta::Role->initialize($role);
            $meta->alias_method('meta' => sub { $meta });
        }

        return $METAS{$role} = $meta;
    }


    my %exports = (
        extends => sub {
            my $meta = _find_meta();
            return subname 'Moose::Role::extends' => sub {
                confess "Moose::Role does not currently support 'extends'"
            };
        },
        with => sub {
            my $meta = _find_meta();
            return subname 'Moose::Role::with' => sub (@) {
                Moose::Util::apply_all_roles($meta, @_)
            };
        },
        requires => sub {
            my $meta = _find_meta();
            return subname 'Moose::Role::requires' => sub (@) {
                confess "Must specify at least one method" unless @_;
                $meta->add_required_methods(@_);
            };
        },
        excludes => sub {
            my $meta = _find_meta();
            return subname 'Moose::Role::excludes' => sub (@) {
                confess "Must specify at least one role" unless @_;
                $meta->add_excluded_roles(@_);
            };
        },
        has => sub {
            my $meta = _find_meta();
            return subname 'Moose::Role::has' => sub ($;%) {
                my ($name, %options) = @_;
                $meta->add_attribute($name, %options)
            };
        },
        before => sub {
            my $meta = _find_meta();
            return subname 'Moose::Role::before' => sub (@&) {
                my $code = pop @_;
                $meta->add_before_method_modifier($_, $code) for @_;
            };
        },
        after => sub {
            my $meta = _find_meta();
            return subname 'Moose::Role::after' => sub (@&) {
                my $code = pop @_;
                $meta->add_after_method_modifier($_, $code) for @_;
            };
        },
        around => sub {
            my $meta = _find_meta();
            return subname 'Moose::Role::around' => sub (@&) {
                my $code = pop @_;
                $meta->add_around_method_modifier($_, $code) for @_;
            };
        },
        # see Moose.pm for discussion
        super => sub {
            return subname 'Moose::Role::super' => sub { return unless $Moose::SUPER_BODY; $Moose::SUPER_BODY->(@Moose::SUPER_ARGS) }
        },
        #next => sub {
        #    return subname 'Moose::Role::next' => sub { @_ = @Moose::SUPER_ARGS; goto \&next::method };
        #},
        override => sub {
            my $meta = _find_meta();
            return subname 'Moose::Role::override' => sub ($&) {
                my ($name, $code) = @_;
                $meta->add_override_method_modifier($name, $code);
            };
        },
        inner => sub {
            my $meta = _find_meta();
            return subname 'Moose::Role::inner' => sub {
                confess "Moose::Role cannot support 'inner'";
            };
        },
        augment => sub {
            my $meta = _find_meta();
            return subname 'Moose::Role::augment' => sub {
                confess "Moose::Role cannot support 'augment'";
            };
        },
        confess => sub {
            return \&Carp::confess;
        },
        blessed => sub {
            return \&Scalar::Util::blessed;
        }
    );

    my $exporter = Sub::Exporter::build_exporter({
        exports => \%exports,
        groups  => {
            default => [':all']
        }
    });

    sub import {
        $CALLER =
            ref $_[1] && defined $_[1]->{into} ? $_[1]->{into}
          : ref $_[1]
          && defined $_[1]->{into_level} ? caller( $_[1]->{into_level} )
          :                                caller();

        # this works because both pragmas set $^H (see perldoc perlvar)
        # which affects the current compilation - i.e. the file who use'd
        # us - which is why we don't need to do anything special to make
        # it affect that file rather than this one (which is already compiled)

        strict->import;
        warnings->import;

        # we should never export to main
        return if $CALLER eq 'main';

        goto $exporter;
    };

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
