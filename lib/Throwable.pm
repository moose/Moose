package Throwable;
use Moose::Role 0.87;
# ABSTRACT: a role for classes that can be thrown

=head1 SYNOPSIS

  package Redirect;
  use Moose;
  with 'Throwable';

  has url => (is => 'ro');

...then later...

  Redirect->throw({ url => $url });

=head1 DESCRIPTION

Throwable is a role for classes that are meant to be thrown as exceptions to
standard program flow.  It is very simple and does only two things: saves any
previous value for C<$@> and calls C<die $self>.

=attr previous_exception

This attribute is created automatically, and stores the value of C<$@> when the
Throwable object is created.

=cut

has 'previous_exception' => (
  is       => 'ro',
  init_arg => undef,
  default  => sub {
    return unless defined $@ and (ref $@ or length $@);
    return $@;
  },
);

=method throw

  Something::Throwable->throw({ attr => $value });

This method will call new, passing all arguments along to new, and will then
use the created object as the only argument to C<die>.

If called on an object that does Throwable, the object will be rethrown.

=cut

sub throw {
  my ($inv) = shift;

  if (blessed $inv) {
    confess "throw called on Throwable object with arguments" if @_;
    die $inv;
  }

  my $throwable = $inv->new(@_);
  die $throwable;
}

no Moose::Role;
1;
