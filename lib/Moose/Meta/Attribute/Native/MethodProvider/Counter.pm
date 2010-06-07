
package Moose::Meta::Attribute::Native::MethodProvider::Counter;
use Moose::Role;

use Scalar::Util qw( looks_like_number );

our $VERSION   = '1.07';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

sub _get_number {
    my $val = $_[1]->( $_[0] );

    unless ( defined $val && looks_like_number($val) && $val == int($val) ) {
        local $Carp::CarpLevel += 3;
        confess 'The ' . $_[2] . ' attribute does not contain an integer';
    }

    return $val;
}

sub reset : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub { $writer->( $_[0], $attr->default( $_[0] ) ) };
}

sub set : method {
    my ( $attr, $reader, $writer, $value ) = @_;
    return sub { $writer->( $_[0], $_[1] ) };
}

sub inc {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub {
        $writer->( $_[0],
            _get_number( $_[0], $reader, $name ) + ( defined( $_[1] ) ? $_[1] : 1 ) );
    };
}

sub dec {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub {
        $writer->( $_[0],
            _get_number( $_[0], $reader, $name ) - ( defined( $_[1] ) ? $_[1] : 1 ) );
    };
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::Attribute::Native::MethodProvider::Counter - role providing method generators for Counter trait

=head1 DESCRIPTION

This is a role which provides the method generators for
L<Moose::Meta::Attribute::Native::Trait::Counter>.  Please check there for
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
