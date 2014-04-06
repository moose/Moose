package Moose::ExceptionFormatter::FullTrace;
use Moose;
with 'Moose::ExceptionFormatter';

sub format_exception {
    my ($self, $exception) = @_;
    return $exception->trace->as_string;
}

1;
