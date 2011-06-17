use strict;
use warnings;

BEGIN {
    eval { require ExtUtils::MakeMaker::Dist::Zilla::Develop };
    if ($@) {
        warn
            "You need to install ExtUtils::MakeMaker::Dist::Zilla::Develop to run this Makefile.PL\n";
        exit 1;
    }

    eval { require Test::Inline };
    if ($@) {
        warn "You need to install Test::Inline to run this Makefile.PL\n";
        exit 1;
    }

    ExtUtils::MakeMaker::Dist::Zilla::Develop->import();
}

use lib 'inc';

use MMHelper;
use MyInline;

system( $^X, 'author/extract-inline-tests', '--quiet' );

eval MMHelper::my_package_subs();

WriteMakefile(
    NAME => 'Moose',
    test => { TESTS => 't/*.t t/*/*.t' },
    CCFLAGS => MMHelper::ccflags_static('dev'),
    MMHelper::mm_args(),
);
