package Moose::Meta::Method;

use strict;
use warnings;

use base 'Class::MOP::Method';

sub _error_thrower {
    my $self = shift;
    require Moose::Meta::Class;
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

    my $inv = $self->_error_thrower;
    # XXX ugh
    $inv = 'Moose::Meta::Class' unless $inv->can('_inline_throw_error');

    # XXX ugh ugh UGH
    my $class = $self->associated_metaclass;
    if ($class) {
        my $class_name = B::perlstring($class->name);
        my $meth_name = B::perlstring($self->name);
        $args = 'method => Class::MOP::class_of(' . $class_name . ')'
              . '->find_method_by_name(' . $meth_name . '), '
              . (defined $args ? $args : '');
    }

    return $inv->_inline_throw_error($msg, $args)
}

1;

# ABSTRACT: A Moose Method metaclass

__END__

=pod

=head1 DESCRIPTION

This class is a subclass of L<Class::MOP::Method> that provides
additional Moose-specific functionality, all of which is private.

To understand this class, you should read the the L<Class::MOP::Method>
documentation.

=head1 INHERITANCE

C<Moose::Meta::Method> is a subclass of L<Class::MOP::Method>.

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=cut
