package Moose::Meta::Attribute::Trait::Native::MethodProvider::Hash;
use Moose::Role;

our $VERSION   = '0.87';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

with 'Moose::Meta::Attribute::Trait::Native::MethodProvider::ImmutableHash';

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

Moose::Meta::Attribute::Trait::Native::MethodProvider::Hash

=head1 DESCRIPTION

This is a role which provides the method generators for
L<Moose::Meta::Attribute::Trait::Native::Hash>.

This role is composed from the
L<Moose::Meta::Attribute::Trait::Native::ImmutableHash> role.

=head1 METHODS

=over 4

=item B<meta>

=back

=head1 PROVIDED METHODS

=over 4

=item B<count>

Returns the number of elements in the hash.

=item B<delete>

Removes the element with the given key

=item B<defined>

Returns true if the value of a given key is defined

=item B<empty>

If the list is populated, returns true. Otherwise, returns false.

=item B<clear>

Unsets the hash entirely.

=item B<exists>

Returns true if the given key is present in the hash

=item B<get>

Returns an element of the hash by its key.

=item B<keys>

Returns the list of keys in the hash.

=item B<set>

Sets the element in the hash at the given key to the given value.

=item B<values>

Returns the list of values in the hash.

=item B<kv>

Returns the  key, value pairs in the hash

=item B<accessor>

If passed one argument, returns the value of the requested key. If passed two
arguments, sets the value of the requested key.

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

