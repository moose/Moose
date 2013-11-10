package inc::GenerateDocs;

use Moose;
with 'Dist::Zilla::Role::AfterBuild', 'Dist::Zilla::Role::FileInjector';
use IPC::System::Simple qw(capturex);
use Path::Tiny;

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

    my $text = capturex($^X, "author/docGenerator.pl");

    my $file_obj = Dist::Zilla::File::InMemory->new(
        name    => "lib/Moose/Manual/Exceptions/Manifest.pod",
        content => $text,
    );

    my $weaver = $self->zilla->plugin_named('SurgicalPodWeaver');

    $weaver->munge_file($file_obj);

    mkdir 'lib/Moose/Manual/Exceptions';
    path($file_obj->name)->spew_raw($file_obj->encoded_content);

    $self->add_file($file_obj);
}

1;
