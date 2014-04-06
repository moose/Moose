package inc::GenerateDocs;

use Moose;
with 'Dist::Zilla::Role::FileGatherer',
    'Dist::Zilla::Role::AfterBuild',
    'Dist::Zilla::Role::FileInjector';
use IPC::System::Simple qw(capturex);
use File::pushd;
use Path::Tiny;
use List::Util 'first';

my $filename = path(qw(lib Moose Manual Exceptions Manifest.pod));

sub gather_files {
    my ($self, $arg) = @_;

    $self->add_file(Dist::Zilla::File::InMemory->new(
        name    => $filename->stringify,
        # more to fill in later
        content => <<'END_POD',
use strict;
use warnings;
package Moose::Manual::Exceptions::Manifest;
# ABSTRACT: Moose's Exception Types

__END__

=for comment insert generated content here
END_POD
    ));
}

sub after_build {
    my ($self, $opts) = @_;
    my $build_dir = $opts->{build_root};

    my $wd = File::pushd::pushd($build_dir);
    unless ( -d 'blib' ) {
        my @builders = @{ $self->zilla->plugins_with( -BuildRunner ) };
        die "no BuildRunner plugins specified" unless @builders;
        $_->build for @builders;
        die "no blib; failed to build properly?" unless -d 'blib';
    }

    # this must be run as a separate process because we need to use the new
    # Moose we just generated, in order to introspect all the exception classes
    $self->log('running author/docGenerator.pl...');
    my $text = capturex($^X, "author/docGenerator.pl");

    my $file_obj = first { $_->name eq $filename } @{$self->zilla->files};

    my $content = $file_obj->content;
    my $pos = index($content, "\n\n=for comment insert generated content here");
    $file_obj->content(substr($content, 0, $pos) . "\n\n" . $text . substr($content, $pos, -1));

    $filename->spew_raw($file_obj->encoded_content);
}

1;
