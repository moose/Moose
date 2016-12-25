use strict;
use warnings;
use Test::More;

my $called;
{
    package Foo;
    use Moose;

    sub BUILD { $called++ }
}

Foo->new;
is($called, 1, "BUILD called from ->new");
$called = 0;
Foo->meta->new_object;
is($called, 1, "BUILD called from ->meta->new_object");
Foo->new({__no_BUILD__ => 1});
is($called, 1, "BUILD not called from ->new with __no_BUILD__");
Foo->meta->new_object({__no_BUILD__ => 1});
is($called, 1, "BUILD not called from ->meta->new_object with __no_BUILD__");

done_testing;
