use strict;
use warnings;

use Test::More;
use Moose::Exception;

my $exception = Moose::Exception->new(message => 'barf!');

like($exception, qr/barf/, 'stringification for regex works');

ok($exception ne 'oh hai', 'direct string comparison works');

ok($exception, 'exception can be treated as a boolean');

done_testing;
