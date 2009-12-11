package Moose::Meta::Attribute::Native::MethodProvider::Array;
use Moose::Role;

use List::Util;
use List::MoreUtils;

our $VERSION = '0.93';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

sub count : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        scalar @{ $reader->( $_[0] ) };
    };
}

sub is_empty : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        scalar @{ $reader->( $_[0] ) } ? 0 : 1;
    };
}

sub first : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        my ( $instance, $predicate ) = @_;
        List::Util::first { $predicate->() } @{ $reader->($instance) };
    };
}

sub map : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        my ( $instance, $f ) = @_;
        CORE::map { $f->() } @{ $reader->($instance) };
    };
}

sub reduce : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        my ( $instance, $f ) = @_;
        our ($a, $b);
        List::Util::reduce { $f->($a, $b) } @{ $reader->($instance) };
    };
}

sub sort : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        my ( $instance, $predicate ) = @_;
        die "Argument must be a code reference"
          if $predicate && ref $predicate ne 'CODE';

        if ($predicate) {
            # Although it would be nice if we could support just using $a and
            # $b like sort already does, using $a or $b once in a package
            # triggers the 'Name "main::a" used only once' warning, and there
            # is no good way to avoid that, since it happens when the file
            # which defines the coderef is compiled, before we even get a
            # chance to see it here. So, we have no real choice but to use
            # normal parameters. --doy
            CORE::sort { $predicate->( $a, $b ) } @{ $reader->($instance) };
        }
        else {
            CORE::sort @{ $reader->($instance) };
        }
    };
}

sub shuffle : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        my ( $instance ) = @_;
        List::Util::shuffle @{ $reader->($instance) };
    };
}

sub grep : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        my ( $instance, $predicate ) = @_;
        CORE::grep { $predicate->() } @{ $reader->($instance) };
    };
}

sub uniq : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        my ( $instance ) = @_;
        List::MoreUtils::uniq @{ $reader->($instance) };
    };
}

sub elements : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        my ($instance) = @_;
        @{ $reader->($instance) };
    };
}

sub join : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        my ( $instance, $separator ) = @_;
        join $separator, @{ $reader->($instance) };
    };
}

sub push : method {
    my ( $attr, $reader, $writer ) = @_;

    if (
        $attr->has_type_constraint
        && $attr->type_constraint->isa(
            'Moose::Meta::TypeConstraint::Parameterized')
      )
    {
        my $container_type_constraint = $attr->type_constraint->type_parameter;
        return sub {
            my $instance = CORE::shift;
            $container_type_constraint->check($_)
              || confess "Value "
              . ( $_ || 'undef' )
              . " did not pass container type constraint '$container_type_constraint'"
              foreach @_;
            CORE::push @{ $reader->($instance) } => @_;
        };
    }
    else {
        return sub {
            my $instance = CORE::shift;
            CORE::push @{ $reader->($instance) } => @_;
        };
    }
}

sub pop : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        CORE::pop @{ $reader->( $_[0] ) };
    };
}

sub unshift : method {
    my ( $attr, $reader, $writer ) = @_;
    if (
        $attr->has_type_constraint
        && $attr->type_constraint->isa(
            'Moose::Meta::TypeConstraint::Parameterized')
      )
    {
        my $container_type_constraint = $attr->type_constraint->type_parameter;
        return sub {
            my $instance = CORE::shift;
            $container_type_constraint->check($_)
              || confess "Value "
              . ( $_ || 'undef' )
              . " did not pass container type constraint '$container_type_constraint'"
              foreach @_;
            CORE::unshift @{ $reader->($instance) } => @_;
        };
    }
    else {
        return sub {
            my $instance = CORE::shift;
            CORE::unshift @{ $reader->($instance) } => @_;
        };
    }
}

sub shift : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        CORE::shift @{ $reader->( $_[0] ) };
    };
}

sub get : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        $reader->( $_[0] )->[ $_[1] ];
    };
}

sub set : method {
    my ( $attr, $reader, $writer ) = @_;
    if (
        $attr->has_type_constraint
        && $attr->type_constraint->isa(
            'Moose::Meta::TypeConstraint::Parameterized')
      )
    {
        my $container_type_constraint = $attr->type_constraint->type_parameter;
        return sub {
            ( $container_type_constraint->check( $_[2] ) )
              || confess "Value "
              . ( $_[2] || 'undef' )
              . " did not pass container type constraint '$container_type_constraint'";
            $reader->( $_[0] )->[ $_[1] ] = $_[2];
        };
    }
    else {
        return sub {
            $reader->( $_[0] )->[ $_[1] ] = $_[2];
        };
    }
}

sub accessor : method {
    my ( $attr, $reader, $writer ) = @_;

    if (
        $attr->has_type_constraint
        && $attr->type_constraint->isa(
            'Moose::Meta::TypeConstraint::Parameterized')
      )
    {
        my $container_type_constraint = $attr->type_constraint->type_parameter;
        return sub {
            my $self = shift;

            if ( @_ == 1 ) {    # reader
                return $reader->($self)->[ $_[0] ];
            }
            elsif ( @_ == 2 ) {    # writer
                ( $container_type_constraint->check( $_[1] ) )
                  || confess "Value "
                  . ( $_[1] || 'undef' )
                  . " did not pass container type constraint '$container_type_constraint'";
                $reader->($self)->[ $_[0] ] = $_[1];
            }
            else {
                confess "One or two arguments expected, not " . @_;
            }
        };
    }
    else {
        return sub {
            my $self = shift;

            if ( @_ == 1 ) {    # reader
                return $reader->($self)->[ $_[0] ];
            }
            elsif ( @_ == 2 ) {    # writer
                $reader->($self)->[ $_[0] ] = $_[1];
            }
            else {
                confess "One or two arguments expected, not " . @_;
            }
        };
    }
}

sub clear : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        @{ $reader->( $_[0] ) } = ();
    };
}

sub delete : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        CORE::splice @{ $reader->( $_[0] ) }, $_[1], 1;
      }
}

sub insert : method {
    my ( $attr, $reader, $writer ) = @_;
    if (
        $attr->has_type_constraint
        && $attr->type_constraint->isa(
            'Moose::Meta::TypeConstraint::Parameterized')
      )
    {
        my $container_type_constraint = $attr->type_constraint->type_parameter;
        return sub {
            ( $container_type_constraint->check( $_[2] ) )
              || confess "Value "
              . ( $_[2] || 'undef' )
              . " did not pass container type constraint '$container_type_constraint'";
            CORE::splice @{ $reader->( $_[0] ) }, $_[1], 0, $_[2];
        };
    }
    else {
        return sub {
            CORE::splice @{ $reader->( $_[0] ) }, $_[1], 0, $_[2];
        };
    }
}

sub splice : method {
    my ( $attr, $reader, $writer ) = @_;
    if (
        $attr->has_type_constraint
        && $attr->type_constraint->isa(
            'Moose::Meta::TypeConstraint::Parameterized')
      )
    {
        my $container_type_constraint = $attr->type_constraint->type_parameter;
        return sub {
            my ( $self, $i, $j, @elems ) = @_;
            ( $container_type_constraint->check($_) )
              || confess "Value "
              . ( defined($_) ? $_ : 'undef' )
              . " did not pass container type constraint '$container_type_constraint'"
              for @elems;
            CORE::splice @{ $reader->($self) }, $i, $j, @elems;
        };
    }
    else {
        return sub {
            my ( $self, $i, $j, @elems ) = @_;
            CORE::splice @{ $reader->($self) }, $i, $j, @elems;
        };
    }
}

sub sort_in_place : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        my ( $instance, $predicate ) = @_;

        die "Argument must be a code reference"
          if $predicate && ref $predicate ne 'CODE';

        my @sorted;
        if ($predicate) {
            @sorted =
              CORE::sort { $predicate->( $a, $b ) } @{ $reader->($instance) };
        }
        else {
            @sorted = CORE::sort @{ $reader->($instance) };
        }

        $writer->( $instance, \@sorted );
    };
}

sub natatime : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        my ( $instance, $n, $f ) = @_;
        my $it = List::MoreUtils::natatime($n, @{ $reader->($instance) });
        if ($f) {
            while (my @vals = $it->()) {
                $f->(@vals);
            }
        }
        $it;
    };
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::Attribute::Native::MethodProvider::Array

=head1 DESCRIPTION

This is a role which provides the method generators for
L<Moose::Meta::Attribute::Native::Trait::Array>. Please check there for
documentation on what methods are provided.

=head1 METHODS

=over 4

=item B<meta>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
