package Moose::Exception;

use Moose;
use Devel::StackTrace;

has 'trace' => (
    is            => 'ro',
    isa           => 'Devel::StackTrace',
    builder       => '_build_trace',
    lazy          => 1,
    documentation => "This attribute is read-only and isa L<Devel::StackTrace>. ".
                     'It is lazy & dependent on $exception->message.'
);

has 'message' => (
    is            => 'ro',
    isa           => 'Str',
    builder       => '_build_message',
    lazy          => 1,
    documentation => "This attribute is read-only and isa Str. ".
                     "It is lazy and has a default value 'Error'."
);

use overload
    '""' => sub {
        my $self = shift;
        return $self->trace->as_string,
    },
    fallback => 1,
;

sub _build_trace {
    my $self = shift;
    Devel::StackTrace->new(
        message => $self->message,
        indent  => 1,
    );
}

sub _build_message {
    "Error";
}

sub BUILD {
    my $self = shift;
    $self->trace;
}

1;

# ABSTRACT: Superclass for Moose internal exceptions

__END__

=pod

=head1 DESCRIPTION

This class contains attributes which are common to all Moose internal
exception classes.

=head1 WARNING WARNING WARNING

If you're writing your own exception classes, you should instead prefer
the L<Throwable> role or the L<Throwable::Error> superclass - this is
effectively a cut-down internal fork of the latter, and not designed
for use in user code.

Of course if you're writing metaclass traits, it would then make sense to
subclass the relevant Moose exceptions - but only then.

=head1 ATTRIBUTES

=over 4

=item B<< $exception->trace >>

This attribute contains the stack trace for the given exception. It
is read-only and isa L<Devel::StackTrace>. It is lazy & dependent
on $exception->message.

=item B<< $exception->message >>

This attribute contains the exception message. It is read-only and isa Str.
It is lazy and has a default value 'Error'. Every subclass of L<Moose::Exception>
is expected to override _build_message method.

=back

=head1 SEE ALSO

=over 4

=item * L<Moose::Manual::Exceptions>

=back

=cut
