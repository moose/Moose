use strict;
use warnings;
package inc::SimpleProvides;

use Moose;
with 'Dist::Zilla::Role::MetaProvider',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [ ':InstallModules' ],
    },
;

sub metadata
{
    my $self = shift;

    my $version = $self->zilla->version;

    return +{
        provides => {
            map {
                # this is an awful hack and assumes ascii package names:
                # please do not cargo-cult this code elsewhere. The proper
                # thing to do is to crack open the file and read the pod name.
                my $filename = $_->name;
                (my $package = $filename) =~ s{[/\\]}{::}g;
                $package =~ s/^lib:://;
                $package =~ s/\.pod$//;
                $package => { file => $filename, version => $version }
            } @{$self->found_files},
        }
    };
}

__PACKAGE__->meta->make_immutable;
