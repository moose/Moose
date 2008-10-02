use strict;
use warnings;
use Test::More tests => 22;
use Moose::Test::Case;

Moose::Test::Case->new->run_tests(
    after_last_pm => sub {
        Foo->meta->make_immutable;
    },
);

