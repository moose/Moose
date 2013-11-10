package inc::GenerateDocs;

use Moose;
with 'Dist::Zilla::Role::AfterBuild', 'Dist::Zilla::Role::FileInjector';
use IPC::System::Simple qw(capturex);

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

    my $zilla = $self->zilla;
    my $version = $zilla->version;
    my $text = capturex($^X, "author/docGenerator.pl", $version);
    my @authors = @{$zilla->authors};
    my $license = $zilla->license;
    my $author_info = "=head1 AUTHORS\n\n=over 4\n\n";
    foreach( @authors ) {
        $author_info .= "=item *\n\n$_\n\n";
    }
    $author_info .= "=back\n\n=head1 COPYRIGHT AND LICENSE\n\n";
    $author_info .= $license->notice;
    $author_info .= "\n=cut\n";

    $text .= $author_info;
    print STDERR "text = ".$text."\n";

    mkdir 'lib/Moose/Manual/Exceptions/';
    my $pod_file;
    open $pod_file, "> lib/Moose/Manual/Exceptions/Manifest.pod" or die $!;
    print $pod_file $text;
    close $pod_file;
    my $file_obj = Dist::Zilla::File::InMemory->new(
        name    => "lib/Moose/Manual/Exceptions/Manifest.pod",
        content => $text,
    );

    $self->add_file($file_obj);
}

1;
