package Moose::Meta::Attribute::Native::MethodProvider::Hash;
use Moose::Role;

our $VERSION   = '0.93';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

sub exists : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub { CORE::exists $reader->( $_[0] )->{ $_[1] } ? 1 : 0 };
}

sub defined : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub { CORE::defined $reader->( $_[0] )->{ $_[1] } ? 1 : 0 };
}

sub get : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        if ( @_ == 2 ) {
            $reader->( $_[0] )->{ $_[1] };
        }
        else {
            my ( $self, @keys ) = @_;
            @{ $reader->($self) }{@keys};
        }
    };
}

sub keys : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub { CORE::keys %{ $reader->( $_[0] ) } };
}

sub values : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub { CORE::values %{ $reader->( $_[0] ) } };
}

sub kv : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        my $h = $reader->( $_[0] );
        map { [ $_, $h->{$_} ] } CORE::keys %{$h};
    };
}

sub elements : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        my $h = $reader->( $_[0] );
        map { $_, $h->{$_} } CORE::keys %{$h};
    };
}

sub count : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub { scalar CORE::keys %{ $reader->( $_[0] ) } };
}

sub is_empty : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub { scalar CORE::keys %{ $reader->( $_[0] ) } ? 0 : 1 };
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
                @{ $reader->($self) }{@keys} = @values;
            }
            else {
                $reader->($self)->{ $keys[0] } = $values[0];
            }
        };
    }
    else {
        return sub {
            if ( @_ == 3 ) {
                $reader->( $_[0] )->{ $_[1] } = $_[2];
            }
            else {
                my ( $self, @kvp ) = @_;
                my ( @keys, @values );

                while (@kvp) {
                    push @keys,   shift @kvp;
                    push @values, shift @kvp;
                }

                @{ $reader->( $_[0] ) }{@keys} = @values;
            }
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
                return $reader->($self)->{ $_[0] };
            }
            elsif ( @_ == 2 ) {    # writer
                ( $container_type_constraint->check( $_[1] ) )
                    || confess "Value "
                    . ( $_[1] || 'undef' )
                    . " did not pass container type constraint '$container_type_constraint'";
                $reader->($self)->{ $_[0] } = $_[1];
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
                return $reader->($self)->{ $_[0] };
            }
            elsif ( @_ == 2 ) {    # writer
                $reader->($self)->{ $_[0] } = $_[1];
            }
            else {
                confess "One or two arguments expected, not " . @_;
            }
        };
    }
}

sub clear : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub { %{ $reader->( $_[0] ) } = () };
}

sub delete : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        my $hashref = $reader->(shift);
        CORE::delete @{$hashref}{@_};
    };
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::Attribute::Native::MethodProvider::Hash

=head1 DESCRIPTION

This is a role which provides the method generators for
L<Moose::Meta::Attribute::Native::Trait::Hash>. Please check there for
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

