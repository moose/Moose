package inc::MakeMaker;

use Moose;

use lib 'inc';

use MMHelper;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_MakeFile_PL_template => sub {
    my $self = shift;

    my $tmpl = super();

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

1;



