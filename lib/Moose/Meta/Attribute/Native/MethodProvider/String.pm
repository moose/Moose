package Moose::Meta::Attribute::Native::MethodProvider::String;
use Moose::Role;

our $VERSION   = '1.07';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

sub _get_string {
    my $val = $_[1]->( $_[0] );

    unless ( defined $val && ! ref $val ) {
        local $Carp::CarpLevel += 3;
        confess 'The ' . $_[2] . ' attribute does not contain a string';
    }

    return $val;
}

sub append : method {
    my ( $attr, $reader, $writer ) = @_;

    my $name = $attr->name;
    return sub { $writer->( $_[0], _get_string( $_[0], $reader, $name ) . $_[1] ) };
}

sub prepend : method {
    my ( $attr, $reader, $writer ) = @_;

    my $name = $attr->name;
    return sub { $writer->( $_[0], $_[1] . _get_string( $_[0], $reader, $name ) ) };
}

sub replace : method {
    my ( $attr, $reader, $writer ) = @_;

    my $name = $attr->name;
    return sub {
        my ( $self, $regex, $replacement ) = @_;
        my $v = _get_string( $self, $reader, $name );

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
    my $name = $attr->name;
    return sub { _get_string( $_[0], $reader, $name ) =~ $_[1] };
}

sub chop : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub {
        my $v = _get_string( $_[0], $reader, $name );
        CORE::chop($v);
        $writer->( $_[0], $v );
    };
}

sub chomp : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub {
        my $v = _get_string( $_[0], $reader, $name );
        chomp($v);
        $writer->( $_[0], $v );
    };
}

sub inc : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub {
        my $v = _get_string( $_[0], $reader, $name );
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
    my $name = $attr->name;
    return sub {
        my $v = _get_string( $_[0], $reader, $name );
        return CORE::length($v);
    };
}

sub substr : method {
    my ( $attr, $reader, $writer ) = @_;
    my $name = $attr->name;
    return sub {
        my $self = shift;
        my $v    = _get_string( $self, $reader, $name );

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

Moose::Meta::Attribute::Native::MethodProvider::String - role providing method generators for String trait

=head1 DESCRIPTION

This is a role which provides the method generators for
L<Moose::Meta::Attribute::Native::Trait::String>. Please check there for
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
