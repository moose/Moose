use strict;
use warnings;

use FindBin qw( $Bin );
use lib "$Bin/../../t/lib";

use Test::More;

use_ok('MyMooseA');
use_ok('MyMooseB');

done_testing;
