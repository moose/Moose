package Moose::Exception;

use Moose;
use Devel::StackTrace;

has 'trace' => (
    is      => 'ro',
    isa     => 'Devel::StackTrace',
    builder => '_build_trace',
    lazy    => 1,
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
