package Moose::Meta::Attribute::Native::MethodProvider::Code;
use Moose::Role;

use Params::Util qw( _CODE );

our $VERSION   = '1.07';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

sub _get_hashref {
    my $val = $_[1]->( $_[0] );

    unless ( _CODE($val) ) {
        local $Carp::CarpLevel += 3;
        confess 'The ' . $_[2] . ' attribute does not contain a subroutine reference';
    }

    return $val;
}

sub execute : method {
    my ($attr, $reader, $writer) = @_;
    my $name = $attr->name;
    return sub {
        my ($self, @args) = @_;
        _get_hashref( $self, $reader, $name )->(@args);
    };
}

sub execute_method : method {
    my ($attr, $reader, $writer) = @_;
    my $name = $attr->name;
    return sub {
        my ($self, @args) = @_;
        _get_hashref( $self, $reader, $name )->($self, @args);
    };
}

no Moose::Role;

1;

__END__

=pod

=head1 NAME

Moose::Meta::Attribute::Native::MethodProvider::Code - role providing method generators for Code trait

=head1 DESCRIPTION

This is a role which provides the method generators for
L<Moose::Meta::Attribute::Native::Trait::Code>. Please check there for
documentation on what methods are provided.

=head1 METHODS

=over 4

=item B<meta>

=back

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHOR

  Florian Ragwitz <rafl@debian.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
