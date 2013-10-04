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

has 'message' => (
    is      => 'ro',
    isa     => 'Str',
    builder => '_build_message',
    lazy    => 1,
);

use overload
    '""' => sub {
        my $self = shift;
        return $self->trace->as_string;
};

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

# ABSTRACT: Superclass of all Moose exceptions

__END__

=pod

=head1 DESCRIPTION

This class contains attributes which are comon to all Moose exceptions
classes.

=head1 ATTRIBUTES

=over 4

=item B<< $exception->trace >>

This attribute contains the stack trace for the given exception. It
is read-only and isa L<Devel::StackTrace>. It is lazy & dependent
on $exception->message.

=item B<< $exception->message >>

This attribute contains the exception message. It is read-only and isa Str.
It is lazy and has a default value 'Error'.

=back

=cut
