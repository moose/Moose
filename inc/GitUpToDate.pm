package inc::GitUpToDate;
use Moose;

with 'Dist::Zilla::Role::BeforeBuild';

sub git {
    if (wantarray) {
        chomp(my @ret = qx{git $_[0]});
        return @ret;
    }
    else {
        chomp(my $ret = qx{git $_[0]});
        return $ret;
    }
}

sub before_build {
    my $self = shift;

    return unless $ENV{DZIL_RELEASING};

    my $branch = git "symbolic-ref HEAD";
    die "Could not get the current branch"
        unless $branch;

    $branch =~ s{refs/heads/}{};

    $self->log("Ensuring branch $branch is up to date");

    git "fetch origin";
    my $origin = git "rev-parse origin/$branch";
    my $head = git "rev-parse HEAD";

    die "Branch $branch is not up to date (origin: $origin, HEAD: $head)"
        if $origin ne $head;


    # now also check that HEAD is current with the release branch
    # that is, that the release branch is an ancestor commit of HEAD.
    my $release_branch = ($self->zilla->plugin_named('Git::CheckFor::CorrectBranch')->release_branch)[0];
    foreach my $remote ('origin/', '')
    {
        my $release_commit = git "rev-parse ${remote}$release_branch";
        my $common_ancestor = git "merge-base $head $release_commit";

        die "Branch $branch does not contain all commits from the current release branch ",
                "(common ancestor for ${remote}$release_branch: $common_ancestor)"
            if $common_ancestor ne $release_commit;
    }
}

1;
