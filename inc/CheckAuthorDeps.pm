use strict;
use warnings;
package inc::CheckAuthorDeps;

# our goal is to verify that the declared authordeps already reflect
# everything in configure + runtime prerequisites -- otherwise, we won't be
# able to bootstrap our built Moose for the purposes of running
# author/docGenerator.pl

use Moose;
with 'Dist::Zilla::Role::AfterBuild';

sub after_build
{
    my $self = shift;

    # get our authordeps
    require Dist::Zilla::Util::AuthorDeps;
    Dist::Zilla::Util::AuthorDeps->VERSION(5.021);

    require CPAN::Meta::Requirements;
    my $authordeps = CPAN::Meta::Requirements->new;
    $authordeps->add_string_requirement(%$_)
        foreach @{ Dist::Zilla::Util::AuthorDeps::extract_author_deps('.') };

    # get our prereqs
    my $prereqs = $self->zilla->prereqs;

    # merge prereqs into authordeps
    my $merged_prereqs = CPAN::Meta::Requirements->new;
    $merged_prereqs->add_requirements($authordeps);
    $merged_prereqs->add_requirements($prereqs->requirements_for('configure', 'requires'));
    $merged_prereqs->add_requirements($prereqs->requirements_for('runtime', 'requires'));

    # remove some false positives we know we already have fulfilled
    $merged_prereqs->clear_requirement('ExtUtils::MakeMaker');
    $merged_prereqs->clear_requirement('Dist::CheckConflicts');

    # the merged set should not be different than the original authordeps.
    require Test::Deep;
    my ($ok, $stack) = Test::Deep::cmp_details(
        $authordeps->as_string_hash,
        Test::Deep::superhashof($merged_prereqs->as_string_hash),
    );

    return if $ok;

    $self->log_fatal('authordeps does not have all prereqs found in configure, runtime prereqs: '
        . Test::Deep::deep_diag($stack));
}

1;
