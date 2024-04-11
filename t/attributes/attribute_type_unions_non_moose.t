use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    package TestAlgoAA;
    sub new { return bless {}, shift }

    package TestAlgoBB;
    sub new { return bless {}, shift }

    package Foo;
    use Moose;

    ::is( ::exception { has 'bar' => (is => 'rw', isa => 'TestAlgoAA | TestAlgoBB') }, undef, "can have union of non-Moose classes" );
}

my $foo = Foo->new;
isa_ok($foo, 'Foo');

is( exception {
    $foo->bar(TestAlgoAA->new)
}, undef, 'set bar successfully with unions\' first type' );

is( exception {
    $foo->bar(TestAlgoBB->new)
}, undef, 'set bar successfully with unions\' second type' );

done_testing;
