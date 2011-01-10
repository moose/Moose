use strict;
use warnings;

use ExtUtils::MakeMaker::Dist::Zilla::Develop;

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
