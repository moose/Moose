package Moose::Meta::Attribute::Native::MethodProvider::String;
use Moose::Role;

our $VERSION   = '0.93';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

sub append : method {
    my ( $attr, $reader, $writer ) = @_;

    return sub { $writer->( $_[0], $reader->( $_[0] ) . $_[1] ) };
}

sub prepend : method {
    my ( $attr, $reader, $writer ) = @_;

    return sub { $writer->( $_[0], $_[1] . $reader->( $_[0] ) ) };
}

sub replace : method {
    my ( $attr, $reader, $writer ) = @_;

    return sub {
        my ( $self, $regex, $replacement ) = @_;
        my $v = $reader->( $_[0] );

        if ( ( ref($replacement) || '' ) eq 'CODE' ) {
            $v =~ s/$regex/$replacement->()/e;
        }
        else {
            $v =~ s/$regex/$replacement/;
        }

        $writer->( $_[0], $v );
    };
}

sub match : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub { $reader->( $_[0] ) =~ $_[1] };
}

sub chop : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        my $v = $reader->( $_[0] );
        CORE::chop($v);
        $writer->( $_[0], $v );
    };
}

sub chomp : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        my $v = $reader->( $_[0] );
        chomp($v);
        $writer->( $_[0], $v );
    };
}

sub inc : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        my $v = $reader->( $_[0] );
        $v++;
        $writer->( $_[0], $v );
    };
}

sub clear : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub { $writer->( $_[0], '' ) }
}

sub length : method {
    my ($attr, $reader, $writer) = @_;
    return sub {
        my $v = $reader->($_[0]);
        return CORE::length($v);
    };
}

sub substr : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub {
        my $self = shift;
        my $v    = $reader->($self);

        my $offset      = defined $_[0] ? shift : 0;
        my $length      = defined $_[0] ? shift : CORE::length($v);
        my $replacement = defined $_[0] ? shift : undef;

        my $ret;
        if ( defined $replacement ) {
            $ret = CORE::substr( $v, $offset, $length, $replacement );
            $writer->( $self, $v );
        }
        else {
            $ret = CORE::substr( $v, $offset, $length );
        }

        return $ret;
    };
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::Attribute::Native::MethodProvider::String

=head1 DESCRIPTION

This is a role which provides the method generators for
L<Moose::Meta::Attribute::Native::Trait::String>. Please check there for
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
