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
