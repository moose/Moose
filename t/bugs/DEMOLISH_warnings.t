use strict;
use warnings;

use lib 't/lib';
use Test::More;
use Test::Requires qw(Test::Warnings);
Test::Warnings->import(':no_end_test');

# Demolition::OnceRemoved has a variable only in scope during the initial `use`
# As it leaves scope, Perl will call DESTROY on it
# (and Moose::Object will then go through its DEMOLISHALL method)
use Demolition::OnceRemoved;
Test::Warnings::had_no_warnings("No DEMOLISH warnings");

done_testing();
