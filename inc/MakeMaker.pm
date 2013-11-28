package inc::MakeMaker;

use Moose;

use lib 'inc';

use MMHelper;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_MakeFile_PL_template => sub {
    my $self = shift;

    my $tmpl = super();
    my $assert_compiler = <<'ASSERT_COMPILER';
# Secondary compile testing via ExtUtils::CBuilder
sub can_xs {
    # Do we have the configure_requires checker?
    unless (eval 'require ExtUtils::CBuilder; ExtUtils::CBuilder->VERSION(0.27); 1') {
        # They don't obey configure_requires, so it is
        # someone old and delicate. Try to avoid hurting
        # them by falling back to an older simpler test.
        return can_cc();
    }

    return ExtUtils::CBuilder->new( quiet => 1 )->have_compiler;
}

# can we locate a (the) C compiler
sub can_cc {
  my @chunks = split(/ /, $Config::Config{cc}) or return;

  # $Config{cc} may contain args; try to find out the program part
  while (@chunks) {
    return can_run("@chunks") || (pop(@chunks), next);
  }

  return;
}

# check if we can run some command
sub can_run {
  my ($cmd) = @_;

  return $cmd if -x $cmd;
  if (my $found_cmd = MM->maybe_command($cmd)) {
    return $found_cmd;
  }

  for my $dir ((split /$Config::Config{path_sep}/, $ENV{PATH}), '.') {
    next if $dir eq '';
    my $abs = File::Spec->catfile($dir, $cmd);
    return $abs if (-x $abs or $abs = MM->maybe_command($abs));
  }

  return;
}

die 'This distribution requires a working compiler' unless can_xs();

ASSERT_COMPILER

    # splice in our stuff after the preamble bits
    # TODO - MMA ought to make this easier.
    $tmpl =~ m/use warnings;\n\n/g;
    $tmpl = substr($tmpl, 0, pos($tmpl)) . $assert_compiler . substr($tmpl, pos($tmpl));


    # TODO: splice this in using 'around _build_WriteMakefile_args'
    my $ccflags = MMHelper::ccflags_dyn();
    $tmpl =~ s/^(WriteMakefile\()/\$WriteMakefileArgs{CCFLAGS} = $ccflags;\n\n$1/m;

    return $tmpl . "\n\n" . MMHelper::my_package_subs();
};

override _build_WriteMakefile_args => sub {
    my $self = shift;

    my $args = super();

    return {
        %{$args},
        MMHelper::mm_args(),
    };
};

override test => sub {
    my $self = shift;

    local $ENV{PERL5LIB} = join ':',
        grep {defined} @ENV{ 'PERL5LIB', 'DZIL_TEST_INC' };

    super();
};

1;
