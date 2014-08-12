package inc::CheckReleaseType;
use Moose;
with 'Dist::Zilla::Role::BeforeRelease';

# this is so I don't accidentally release 2.x<odd>xx without the --trial
# option, which has very nearly happened a few times.

sub before_release
{
    my $self = shift;
    my $version = $self->zilla->version;

    $version =~ m/^\d\.\d{4}$/
        or $self->log_fatal("version $version doesn't seem to conform to the normal specification!");

    my $digit = substr($version, 3, 1);
    if ($self->zilla->is_trial)
    {
        $digit % 2 == 1
            or $self->log_fatal('-TRIAL releases must be numbered 2.x{ODD}xx!');
    }
    else
    {
        $digit % 2 == 0
            or $self->log_fatal('stable releases must be numbered 2.x{EVEN}xx!');

        # Moose::Manual::Support says:
        # 2.x{EVEN}00 must be January, April, July, October only.
        if (substr($version, -2, 2) eq '00')
        {
            # month is 0..11
            my $month = (gmtime(time))[4];
            $month % 3 == 0
                or $self->log_fatal('2.x{EVEN}00 releases can only occur in January, April, July or October!');
        }
    }
}
