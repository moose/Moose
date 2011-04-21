package inc::Clean;
use Moose;

with 'Dist::Zilla::Role::BeforeBuild';

sub before_build {
    my $self = shift;

    if (-e 'Makefile') {
        $self->log("Running make distclean to clear out build cruft");
        system("$^X Makefile.PL && make distclean");
    }

    if (-e 'META.yml') {
        $self->log("Removing existing META.yml file");
        unlink('META.yml');
    }
}
