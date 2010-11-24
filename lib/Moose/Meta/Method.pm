package Moose::Meta::Method;

use strict;
use warnings;

our $VERSION   = '1.21';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Class::MOP::MiniTrait;

use base 'Class::MOP::Method';

Class::MOP::MiniTrait::apply(__PACKAGE__, 'Moose::Meta::Object::Trait');

sub _error_thrower {
    my $self = shift;
    ( ref $self && $self->associated_metaclass ) || "Moose::Meta::Class";
}

sub throw_error {
    my $self = shift;
    my $inv = $self->_error_thrower;
    unshift @_, "message" if @_ % 2 == 1;
    unshift @_, method => $self if ref $self;
    unshift @_, $inv;
    my $handler = $inv->can("throw_error");
    goto $handler; # to avoid incrementing depth by 1
}

sub _inline_throw_error {
    my ( $self, $msg, $args ) = @_;
    "\$meta->throw_error($msg" . ($args ? ", $args" : "") . ")"; # FIXME makes deparsing *REALLY* hard
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::Method - A Moose Method metaclass

=head1 DESCRIPTION

This class is a subclass of L<Class::MOP::Method> that provides
additional Moose-specific functionality, all of which is private.

To understand this class, you should read the the L<Class::MOP::Method>
documentation.

=head1 INHERITANCE

C<Moose::Meta::Method> is a subclass of L<Class::MOP::Method>.

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2010 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
