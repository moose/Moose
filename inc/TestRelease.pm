package inc::TestRelease;

use Moose;

extends 'Dist::Zilla::Plugin::TestRelease';

around before_release => sub {
    my $orig = shift;
    my $self = shift;

    local $ENV{MOOSE_TEST_MD} = 1 if not $self->zilla->is_trial;
    local $ENV{AUTHOR_TESTING} = 1 if not $self->zilla->is_trial;

    $self->$orig(@_);
};

1;
