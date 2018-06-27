use strict;
use warnings;

use lib 't/lib';
use Test::More tests => 2; # Test::Warnings re-tests had_no_warnings implicitly
use Test::Requires qw(Test::Warnings);

use Demolition::OnceRemoved;
Test::Warnings::had_no_warnings("No DEMOLISH warnings");
