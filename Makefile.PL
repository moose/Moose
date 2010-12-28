use strict;
use warnings;

use Config;
use ExtUtils::MakeMaker;

use lib 'inc';

use MMHelper;

warn <<'EOF';

  ********************************* WARNING **********************************

  This module uses Dist::Zilla for development. This Makefile.PL will let you
  run the tests, but you are encouraged to install Dist::Zilla and the needed
  plugins if you intend on doing any serious hacking.

  ****************************************************************************

EOF

eval MMHelper::my_package_subs();

WriteMakefile(
    NAME => 'Moose',
    test => { TESTS => 't/*.t t/*/*.t' },
    MMHelper::mm_args(q{.}),
);
