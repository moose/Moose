package inc::TestRelease;

use Moose;

extends 'Dist::Zilla::Plugin::TestRelease';

around before_release => sub {
    my $orig = shift;
    my $self = shift;

    local $ENV{MOOSE_TEST_MD} = $self->zilla->is_trial
        ? $ENV{MOOSE_TEST_MD}
        : 1;

    $self->$orig(@_);
};

1;
