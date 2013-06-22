package Moose::Exception;

use Moose;
use Devel::StackTrace;

has 'trace' => (
    is      => 'ro',
    isa     => 'Devel::StackTrace',
    builder => '_build_trace',
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

sub BUILD {
    my $self = shift;
    $self->trace;
}

1;
