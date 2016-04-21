package inc::MakeMaker;

use Moose;

use lib 'inc';

use MMHelper;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_MakeFile_PL_template => sub {
    my $self = shift;

    my $tmpl = super();
    my $assert_compiler = <<'ASSERT_COMPILER';
# Secondary compile testing via ExtUtils::HasCompiler
use lib 'inc';
use ExtUtils::HasCompiler 0.013 'can_compile_loadable_object';
die 'This distribution requires a working compiler'
    unless can_compile_loadable_object(quiet => 1);

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
