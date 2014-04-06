package Moose::ExceptionFormatter::NoMoose;
use Moose;
with 'Moose::ExceptionFormatter';

sub format_exception {
    my ($self, $exception) = @_;
    my $trace              = $exception->trace;
    my $traces_ref         = $trace->frames( $self->_filter_frames($trace->frames()));
    return $trace->as_string;
}

sub _filter_frames {
    shift;
    my @dirs_and_files_to_be_excluded = (
        qr/Moose(\.pm|\/.+)/,
        qr/Class\/MOP(\.pm|\/.+)/,
        qr/metaclass\.pm/,
    );

    my $i;
    my @traces = @_;

    for( $i = 0; $i <= $#traces; $i++ ) {
        my $frame = $traces[ $i ];
        my $file_name = $frame->filename;
        unless( grep { $file_name =~ /$_/ } @dirs_and_files_to_be_excluded ) {
            last;
        }
    }

    my @desired_frames = @traces[ $i..$#traces ];
    return @desired_frames;
}

1;
