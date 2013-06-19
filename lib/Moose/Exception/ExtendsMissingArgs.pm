package Moose::Exception::ExtendsMissingArgs;

use Moose;
use Devel::StackTrace;

has 'trace' => (
    is => 'rw',
    isa => 'Devel::StackTrace',
    default => sub { Devel::StackTrace->new(
        message => "Must derive at least one class",
        indent => 1, );
    },
);

use overload
    '""' => sub {
        my $self = shift;
        return $self->trace->as_string;
};
1;
