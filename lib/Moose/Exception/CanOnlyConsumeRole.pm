package Moose::Exception::CanOnlyConsumeRole;

use Moose;
use Devel::StackTrace;

has 'role_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'trace' => (
    is      => 'ro',
    isa     => 'Devel::StackTrace',
    builder => '_build_trace',
    lazy    => 1,
);

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

sub message {
    my $self = shift;
    "You can only consume roles, ".$self->role_name." is not a Moose role";
}

use overload
    '""' => sub {
        my $self = shift;
        return $self->trace->as_string;
};
1;
