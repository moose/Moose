use strict;
use warnings;

use Test::Builder::Tester;
use Test::More;

use Test::Moose;

{
    package Foo;
    use Moose;

    has 'foo', is => 'bare';
}

{
    package Bar;
    use Moose;

    extends 'Foo';

    has 'bar', is => 'bare';
}


test_out('ok 1 - ... lacks_attribute_ok(Foo, bar) passes');
lacks_attribute_ok('Foo', 'bar', '... lacks_attribute_ok(Foo, bar) passes');

test_out ('not ok 2 - ... lacks_attribute_ok(Foo, foo) fails');
test_fail (+1);
lacks_attribute_ok('Foo', 'foo', '... lacks_attribute_ok(Foo, foo) fails');

test_out('not ok 3 - ... lacks_attribute_ok(Bar, foo) fails');
test_fail (+1);
lacks_attribute_ok('Bar', 'foo', '... lacks_attribute_ok(Bar, foo) fails');

test_out('not ok 4 - ... lacks_attribute_ok(Bar, bar) fails');
test_fail (+1);
lacks_attribute_ok('Bar', 'bar', '... lacks_attribute_ok(Bar, bar) fails');

test_out('ok 5 - ... lacks_attribute_ok(Bar, baz) passes');
lacks_attribute_ok('Bar', 'baz', '... lacks_attribute_ok(Bar, baz) passes');

test_test ('lacks_attribute_ok');

done_testing;
