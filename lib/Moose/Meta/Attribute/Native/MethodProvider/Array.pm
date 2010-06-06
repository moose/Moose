package Moose::Meta::Attribute::Native::MethodProvider::Array;
use Moose::Role;

use List::Util;
use List::MoreUtils;
use Params::Util qw( _ARRAY0 );

our $VERSION = '1.07';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

sub _get_arrayref {
    my $val = $_[1]->( $_[0] );

    unless ( _ARRAY0($val) ) {
        local $Carp::CarpLevel += 3;
        confess 'The ' . $_[2] . ' attribute does not contain an array reference';
    }

    return $val;
}

sub count : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub {
        scalar @{ _get_arrayref( $_[0], $reader, $name ) };
    };
}

sub is_empty : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub {
        scalar @{ _get_arrayref( $_[0], $reader, $name ) } ? 0 : 1;
    };
}

sub first : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub {
        my ( $instance, $predicate ) = @_;
        List::Util::first { $predicate->() } @{ _get_arrayref( $instance, $reader, $name ) };
    };
}

sub map : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub {
        my ( $instance, $f ) = @_;
        CORE::map { $f->() } @{ _get_arrayref( $instance, $reader, $name ) };
    };
}

sub reduce : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub {
        my ( $instance, $f ) = @_;
        our ($a, $b);
        List::Util::reduce { $f->($a, $b) } @{ _get_arrayref( $instance, $reader, $name ) };
    };
}

sub sort : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
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
            CORE::sort { $predicate->( $a, $b ) } @{ _get_arrayref( $instance, $reader, $name ) };
        }
        else {
            CORE::sort @{ _get_arrayref( $instance, $reader, $name ) };
        }
    };
}

sub shuffle : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub {
        List::Util::shuffle @{ _get_arrayref( $_[0], $reader, $name ) };
    };
}

sub grep : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub {
        my ( $instance, $predicate ) = @_;
        CORE::grep { $predicate->() } @{ _get_arrayref( $instance, $reader, $name ) };
    };
}

sub uniq : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub {
        List::MoreUtils::uniq @{ _get_arrayref( $_[0], $reader, $name ) };
    };
}

sub elements : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub {
        @{ _get_arrayref( $_[0], $reader, $name ) };
    };
}

sub join : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub {
        my ( $instance, $separator ) = @_;
        join $separator, @{ _get_arrayref( $instance, $reader, $name ) };
    };
}

sub push : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
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

            CORE::push @{ _get_arrayref( $instance, $reader, $name ) } => @_;
        };
    }
    else {
        return sub {
            my $instance = CORE::shift;
            CORE::push @{ _get_arrayref( $instance, $reader, $name ) } => @_;
        };
    }
}

sub pop : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub {
        CORE::pop @{ _get_arrayref( $_[0], $reader, $name ) };
    };
}

sub unshift : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
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
            CORE::unshift @{ _get_arrayref( $instance, $reader, $name ) } => @_;
        };
    }
    else {
        return sub {
            my $instance = CORE::shift;
            CORE::unshift @{ _get_arrayref( $instance, $reader, $name ) } => @_;
        };
    }
}

sub shift : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub {
        CORE::shift @{ _get_arrayref( $_[0], $reader, $name ) };
    };
}

sub get : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub {
        _get_arrayref( $_[0], $reader, $name )->[ $_[1] ];
    };
}

sub set : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
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
            _get_arrayref( $_[0], $reader, $name )->[ $_[1] ] = $_[2];
        };
    }
    else {
        return sub {
            _get_arrayref( $_[0], $reader, $name )->[ $_[1] ] = $_[2];
        };
    }
}

sub accessor : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
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
                return _get_arrayref( $self, $reader, $name )->[ $_[0] ];
            }
            elsif ( @_ == 2 ) {    # writer
                ( $container_type_constraint->check( $_[1] ) )
                  || confess "Value "
                  . ( $_[1] || 'undef' )
                  . " did not pass container type constraint '$container_type_constraint'";
                _get_arrayref( $self, $reader, $name )->[ $_[0] ] = $_[1];
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
                return _get_arrayref( $self, $reader, $name )->[ $_[0] ];
            }
            elsif ( @_ == 2 ) {    # writer
                _get_arrayref( $self, $reader, $name )->[ $_[0] ] = $_[1];
            }
            else {
                confess "One or two arguments expected, not " . @_;
            }
        };
    }
}

sub clear : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub {
        @{ _get_arrayref( $_[0], $reader, $name ) } = ();
    };
}

sub delete : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub {
        CORE::splice @{ _get_arrayref( $_[0], $reader, $name ) }, $_[1], 1;
    };
}

sub insert : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
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
            CORE::splice @{ _get_arrayref( $_[0], $reader, $name ) }, $_[1], 0, $_[2];
        };
    }
    else {
        return sub {
            CORE::splice @{ _get_arrayref( $_[0], $reader, $name ) }, $_[1], 0, $_[2];
        };
    }
}

sub splice : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
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
            CORE::splice @{ _get_arrayref( $self, $reader, $name ) }, $i, $j, @elems;
        };
    }
    else {
        return sub {
            my ( $self, $i, $j, @elems ) = @_;
            CORE::splice @{ _get_arrayref( $self, $reader, $name ) }, $i, $j, @elems;
        };
    }
}

sub sort_in_place : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub {
        my ( $instance, $predicate ) = @_;

        die "Argument must be a code reference"
          if $predicate && ref $predicate ne 'CODE';

        my @sorted;
        if ($predicate) {
            @sorted =
              CORE::sort { $predicate->( $a, $b ) } @{ _get_arrayref( $instance, $reader, $name ) };
        }
        else {
            @sorted = CORE::sort @{ _get_arrayref( $instance, $reader, $name ) };
        }

        $writer->( $instance, \@sorted );
    };
}

sub natatime : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub {
        my ( $instance, $n, $f ) = @_;
        my $it = List::MoreUtils::natatime($n, @{ _get_arrayref( $instance, $reader, $name ) });
        return $it unless $f;

        while (my @vals = $it->()) {
            $f->(@vals);
        }

        return;
    };
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::Attribute::Native::MethodProvider::Array - role providing method generators for Array trait

=head1 DESCRIPTION

This is a role which provides the method generators for
L<Moose::Meta::Attribute::Native::Trait::Array>. Please check there for
documentation on what methods are provided.

=head1 METHODS

=over 4

=item B<meta>

=back

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
