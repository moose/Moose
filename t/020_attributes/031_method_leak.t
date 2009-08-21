use strict;
use warnings;

use Test::More;
#use Devel::Peek;

BEGIN {
    eval "use Test::LeakTrace;";
    plan skip_all => "Test::LeakTrace is required for this test" if $@;
}

use Test::More tests => 5;
use Class::MOP;

{
    package Foo;
    use Moose;
}


my $expected = ($] == 5.010_000) ? 3 : 0; # for a bug on 5.10.0

leaks_cmp_ok {
    my $meta = Foo->meta;
    $meta->add_attribute(foo => (reader => 'foo'));
    $meta->remove_attribute('foo');
} '<=', $expected, 'add_attribute with reader and remove_attribute';

leaks_cmp_ok {
    my $meta = Foo->meta;
    $meta->add_attribute(foo => (writer => 'foo'));
    $meta->remove_attribute('foo');
} '<=', $expected, 'add_attribute with writer and remove_attribute';


leaks_cmp_ok {
    my $meta = Foo->meta;
    $meta->add_attribute(foo => (accessor => 'foo'));
    $meta->remove_attribute('foo');
} '<=', $expected, 'add_attribute with accessor and remove_attribute';

leaks_cmp_ok {
    my $meta = Foo->meta;
    $meta->add_attribute(foo => (predicate => 'foo'));
    $meta->remove_attribute('foo');
} '<=', $expected, 'add_attribute with predicate and remove_attribute';

leaks_cmp_ok {
    my $meta = Foo->meta;
    $meta->add_attribute(foo => (clearer => 'foo'));
    $meta->remove_attribute('foo');
} '<=', $expected, 'add_attribute with clearer and remove_attribute';

