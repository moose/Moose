package inc::CheckDelta;
use Moose;

use Path::Class;

with 'Dist::Zilla::Role::BeforeRelease';

sub before_release {
    my $self = shift;

    my ($delta) = grep { $_->name eq 'lib/Moose/Manual/Delta.pod' }
                       @{ $self->zilla->files };

    die "Moose::Manual::Delta still contains \$NEXT"
        if $delta->content =~ /\$NEXT/;
}

1;
