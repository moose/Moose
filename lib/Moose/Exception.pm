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
