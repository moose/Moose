package Moose::ExceptionFormatter::NoTrace;
use Moose;
with 'Moose::ExceptionFormatter';

sub format_exception {
    my ($self, $exception) = @_;
    my $trace              = $exception->trace;
    my $bottom_frame;
    if( $trace->frame_count() > 2 ) {
        $bottom_frame = $trace->frame(1)->as_string();
    } else {
        $bottom_frame = $trace->frame(0)->as_string();
    }
    my $message      = $exception->message;
    return "$message at\n$bottom_frame\n";
}

1;
