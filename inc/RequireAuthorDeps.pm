package inc::RequireAuthorDeps;

use Moose;

use Try::Tiny;

with 'Dist::Zilla::Role::BeforeRelease';

sub before_release {
    my $self = shift;

    $self->log("Ensuring all author dependencies are installed");
    my $req = Version::Requirements->new;
    my $prereqs = $self->zilla->prereqs;

    for my $phase (qw(build test configure runtime develop)) {
        $req->add_requirements($prereqs->requirements_for($phase, 'requires'));
    }

    for my $mod (grep { $_ ne 'perl' } $req->required_modules) {
        Class::MOP::load_class($mod);
    }
}

1;
