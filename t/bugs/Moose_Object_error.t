use strict;
use warnings;

use FindBin qw( $Bin );
use lib "$Bin/../../t/lib";

use Test::More;

use_ok('MyMooseObject');

done_testing;
