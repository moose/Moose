package inc::Clean;
use Moose;

with 'Dist::Zilla::Role::BeforeBuild',
    'Dist::Zilla::Role::AfterBuild';
use Path::Tiny;
use File::pushd 'pushd';
use Config;

sub before_build { shift->_clean('.') }

sub after_build {
    my ($self, $opts) = @_;

    $self->_clean($opts->{build_root});

    my $iter = path($opts->{build_root})->iterator({ recurse => 1 });
    my %found_files;
    while (my $found_file = $iter->()) {
        next if -d $found_file;
        ++$found_files{ $found_file->relative($opts->{build_root}) };
    }
    delete $found_files{$_->name} foreach @{ $self->zilla->files };

    $self->log(join("\n",
        "WARNING: Files were left behind in $opts->{build_root} that were not explicitly added:",
        sort keys %found_files,
    )) if keys %found_files;
}

sub _clean {
    my ($self, $build_dir) = @_;

    my $cwd = pushd $build_dir;
    if (-e 'Makefile') {

        my $make = $Config{make} || 'make';

        $self->log("Running $make distclean in $build_dir to clear out build cruft");
        my $pid = fork;
        unless ($pid) {
            close(STDIN);
            close(STDOUT);
            close(STDERR);
            { exec("$^X Makefile.PL && $make distclean") }
            die "couldn't exec: $!";
        }
        waitpid($pid, 0) if $pid;
    }
}
