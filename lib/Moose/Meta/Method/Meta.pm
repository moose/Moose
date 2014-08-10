package Moose::Meta::Method::Meta;
our $VERSION = '2.2006';

use strict;
use warnings;

use parent 'Moose::Meta::Method',
         'Class::MOP::Method::Meta';

sub _is_caller_mop_internal {
    my $self = shift;
    my ($caller) = @_;
    return 1 if $caller =~ /^Moose(?:::|$)/;
    return $self->SUPER::_is_caller_mop_internal($caller);
}

# XXX: ugh multiple inheritance
sub wrap {
    my $class = shift;
    return $class->Class::MOP::Method::Meta::wrap(@_);
}

sub _make_compatible_with {
    my $self = shift;
    return $self->Class::MOP::Method::Meta::_make_compatible_with(@_);
}

1;

# ABSTRACT: A Moose Method metaclass for C<meta> methods

__END__

=pod

=head1 DESCRIPTION

This is a subclass of L<Moose::Meta::Method> which represents the C<meta>
method installed into classes which use L<Moose>.

=head1 INHERITANCE

C<Moose::Meta::Method::Meta> is a subclass of L<Moose::Meta::Method> I<and>
C<Class::MOP::Method::Meta>. All of the methods for
C<Moose::Meta::Method::Meta> and C<Class::MOP::Method::Meta> are documented
here.

=head1 METHODS

This class provides the following method:

=head2 Moose::Meta::Method::Meta->wrap($metamethod, %options)

This is the constructor. It accepts a L<Moose::Meta::Method> object and a hash
of options. The options accepted are identical to the ones accepted by
L<Moose::Meta::Method>, except that C<body> cannot be passed (it will be
generated automatically).

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=cut
