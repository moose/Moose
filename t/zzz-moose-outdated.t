use strict;
use warnings;

use Test::More;
use Moose::Conflicts;

eval { Moose::Conflicts->check_conflicts };
diag $@ if $@;

pass;

done_testing;
