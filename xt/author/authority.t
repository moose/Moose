use strict;
use warnings;

use Test::More;
BEGIN {
    plan skip_all => 'this test requires a built dist'
        unless -f 'MANIFEST' && -f 'META.json';
}

use Moose ();

# this is used in Moo::sification
ok(defined $Moose::AUTHORITY, '$AUTHORITY is set in the main module');

done_testing;
