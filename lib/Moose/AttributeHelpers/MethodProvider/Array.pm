package Moose::AttributeHelpers::MethodProvider::Array;
use Moose::Role;

our $VERSION   = '0.87';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

with 'Moose::AttributeHelpers::MethodProvider::List';

sub push : method {
    my ( $attr, $reader, $writer ) = @_;

    if (
        $attr->has_type_constraint
        && $attr->type_constraint->isa(
            'Moose::Meta::TypeConstraint::Parameterized')
        ) {
        my $container_type_constraint
            = $attr->type_constraint->type_parameter;
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
        ) {
        my $container_type_constraint
            = $attr->type_constraint->type_parameter;
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
        ) {
        my $container_type_constraint
            = $attr->type_constraint->type_parameter;
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
        ) {
        my $container_type_constraint
            = $attr->type_constraint->type_parameter;
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
        ) {
        my $container_type_constraint
            = $attr->type_constraint->type_parameter;
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
        ) {
        my $container_type_constraint
            = $attr->type_constraint->type_parameter;
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
            @sorted = CORE::sort { $predicate->( $a, $b ) }
            @{ $reader->($instance) };
        }
        else {
            @sorted = CORE::sort @{ $reader->($instance) };
        }

        $writer->( $instance, \@sorted );
    };
}

1;

__END__

=pod

=head1 NAME

Moose::AttributeHelpers::MethodProvider::Array

=head1 DESCRIPTION

This is a role which provides the method generators for
L<Moose::AttributeHelpers::Collection::Array>.

=head1 METHODS

=over 4

=item B<meta>

=back

=head1 PROVIDED METHODS

This module also consumes the B<List> method providers, to
see those provided methods, refer to that documentation.

=over 4

=item B<get>

=item B<pop>

=item B<push>

=item B<set>

=item B<shift>

=item B<unshift>

=item B<clear>

=item B<delete>

=item B<insert>

=item B<splice>

=item B<sort_in_place>

Sorts the array I<in place>, modifying the value of the attribute.

You can provide an optional subroutine reference to sort with (as you
can with the core C<sort> function). However, instead of using C<$a>
and C<$b>, you will need to use C<$_[0]> and C<$_[1]> instead.

=item B<accessor>

If passed one argument, returns the value of the requested element.
If passed two arguments, sets the value of the requested element.

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
