package inc::GenerateDocs;

use Moose;
with 'Dist::Zilla::Role::AfterBuild', 'Dist::Zilla::Role::FileInjector';
use Class::Load 0.07 qw(load_class);

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

  system($^X, 'author/docGenerator.pl');
  my $file_obj = Dist::Zilla::File::OnDisk->new(
    name    => "lib/Moose/Manual/Exceptions/Manifest.pod",
  );

  $self->add_file($file_obj);
}

1;
