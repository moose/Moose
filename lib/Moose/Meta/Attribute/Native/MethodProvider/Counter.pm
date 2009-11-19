
package Moose::Meta::Attribute::Native::MethodProvider::Counter;
use Moose::Role;

our $VERSION   = '0.93';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

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
    return sub {
        $writer->( $_[0],
            $reader->( $_[0] ) + ( defined( $_[1] ) ? $_[1] : 1 ) );
    };
}

sub dec {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        $writer->( $_[0],
            $reader->( $_[0] ) - ( defined( $_[1] ) ? $_[1] : 1 ) );
    };
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::Attribute::Native::MethodProvider::Counter

=head1 DESCRIPTION

This is a role which provides the method generators for
L<Moose::Meta::Attribute::Native::Trait::Counter>.  Please check there for
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
