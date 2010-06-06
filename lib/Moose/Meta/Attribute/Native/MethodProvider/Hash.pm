package Moose::Meta::Attribute::Native::MethodProvider::Hash;
use Moose::Role;

use Params::Util qw( _HASH0 );

our $VERSION   = '1.07';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

sub _get_hashref {
    my $val = $_[1]->( $_[0] );

    unless ( _HASH0($val) ) {
        local $Carp::CarpLevel += 3;
        confess 'The ' . $_[2] . ' attribute does not contain a hash reference';
    }

    return $val;
}

sub exists : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub { CORE::exists _get_hashref( $_[0], $reader, $name )->{ $_[1] } ? 1 : 0 };
}

sub defined : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub { CORE::defined _get_hashref( $_[0], $reader, $name )->{ $_[1] } ? 1 : 0 };
}

sub get : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub {
        if ( @_ == 2 ) {
            _get_hashref( $_[0], $reader, $name )->{ $_[1] };
        }
        else {
            my ( $self, @keys ) = @_;
            @{ _get_hashref( $self, $reader, $name ) }{@keys};
        }
    };
}

sub keys : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub { CORE::keys %{ _get_hashref( $_[0], $reader, $name ) } };
}

sub values : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub { CORE::values %{ _get_hashref( $_[0], $reader, $name ) } };
}

sub kv : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub {
        my $h = _get_hashref( $_[0], $reader, $name );
        map { [ $_, $h->{$_} ] } CORE::keys %{$h};
    };
}

sub elements : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub {
        my $h = _get_hashref( $_[0], $reader, $name );
        map { $_, $h->{$_} } CORE::keys %{$h};
    };
}

sub count : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub { scalar CORE::keys %{ _get_hashref( $_[0], $reader, $name ) } };
}

sub is_empty : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub { scalar CORE::keys %{ _get_hashref( $_[0], $reader, $name ) } ? 0 : 1 };
}


sub set : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    if (
        $attr->has_type_constraint
        && $attr->type_constraint->isa(
            'Moose::Meta::TypeConstraint::Parameterized')
        ) {
        my $container_type_constraint
            = $attr->type_constraint->type_parameter;
        return sub {
            my ( $self, @kvp ) = @_;

            my ( @keys, @values );

            while (@kvp) {
                my ( $key, $value ) = ( shift(@kvp), shift(@kvp) );
                ( $container_type_constraint->check($value) )
                    || confess "Value "
                    . ( $value || 'undef' )
                    . " did not pass container type constraint '$container_type_constraint'";
                push @keys,   $key;
                push @values, $value;
            }

            if ( @values > 1 ) {
                @{ _get_hashref( $self, $reader, $name ) }{@keys} = @values;
            }
            else {
                _get_hashref( $self, $reader, $name )->{ $keys[0] } = $values[0];
            }
        };
    }
    else {
        return sub {
            if ( @_ == 3 ) {
                _get_hashref( $_[0], $reader, $name )->{ $_[1] } = $_[2];
            }
            else {
                my ( $self, @kvp ) = @_;
                my ( @keys, @values );

                while (@kvp) {
                    push @keys,   shift @kvp;
                    push @values, shift @kvp;
                }

                @{ _get_hashref( $self, $reader, $name ) }{@keys} = @values;
            }
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
        ) {
        my $container_type_constraint
            = $attr->type_constraint->type_parameter;
        return sub {
            my $self = shift;

            if ( @_ == 1 ) {    # reader
                return _get_hashref( $self, $reader, $name )->{ $_[0] };
            }
            elsif ( @_ == 2 ) {    # writer
                ( $container_type_constraint->check( $_[1] ) )
                    || confess "Value "
                    . ( $_[1] || 'undef' )
                    . " did not pass container type constraint '$container_type_constraint'";
                _get_hashref( $self, $reader, $name )->{ $_[0] } = $_[1];
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
                return _get_hashref( $self, $reader, $name )->{ $_[0] };
            }
            elsif ( @_ == 2 ) {    # writer
                _get_hashref( $self, $reader, $name )->{ $_[0] } = $_[1];
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
    return sub { %{ _get_hashref( $_[0], $reader, $name ) } = () };
}

sub delete : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub {
        my $self = shift;
        CORE::delete @{ _get_hashref( $self, $reader, $name ) }{@_};
    };
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::Attribute::Native::MethodProvider::Hash - role providing method generators for Hash trait

=head1 DESCRIPTION

This is a role which provides the method generators for
L<Moose::Meta::Attribute::Native::Trait::Hash>. Please check there for
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

