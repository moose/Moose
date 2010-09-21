package Moose::Meta::Attribute::Native::MethodProvider::Code;
use Moose::Role;

our $VERSION   = '1.14';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

sub execute : method {
    my ($attr, $reader, $writer) = @_;
    return sub {
        my ($self, @args) = @_;
        $reader->($self)->(@args);
    };
}

sub execute_method : method {
    my ($attr, $reader, $writer) = @_;
    return sub {
        my ($self, @args) = @_;
        $reader->($self)->($self, @args);
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
