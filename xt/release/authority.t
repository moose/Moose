use strict;
use warnings;

use Test::More;
use Moose ();

# this is used in Moo::sification
ok(defined $Moose::AUTHORITY, '$AUTHORITY is set in the main module');

done_testing;
