#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 17;

use MetaTest;

{
    package Role::Foo;
    use Moose::Role;

    sub foo { (caller(0))[3] }
}

{
    package ClassA;
    use Moose;

    with 'Role::Foo';
}

skip_meta {
    my $meth = ClassA->meta->get_method('foo');
    ok( $meth, 'ClassA has a foo method' );
    isa_ok( $meth, 'Moose::Meta::Method' );
    is( $meth->original_method, Role::Foo->meta->get_method('foo'),
        'ClassA->foo was cloned from Role::Foo->foo' );
    is( $meth->fully_qualified_name, 'ClassA::foo',
        'fq name is ClassA::foo' );
    is( $meth->original_fully_qualified_name, 'Role::Foo::foo',
        'original fq name is Role::Foo::foo' );
} 5;

{
    package Role::Bar;
    use Moose::Role;
    with 'Role::Foo';

    sub bar { }
}

skip_meta {
    my $meth = Role::Bar->meta->get_method('foo');
    ok( $meth, 'Role::Bar has a foo method' );
    is( $meth->original_method, Role::Foo->meta->get_method('foo'),
        'Role::Bar->foo was cloned from Role::Foo->foo' );
    is( $meth->fully_qualified_name, 'Role::Bar::foo',
        'fq name is Role::Bar::foo' );
    is( $meth->original_fully_qualified_name, 'Role::Foo::foo',
        'original fq name is Role::Foo::foo' );
} 4;

{
    package ClassB;
    use Moose;

    with 'Role::Bar';
}

skip_meta {
    my $meth = ClassB->meta->get_method('foo');
    ok( $meth, 'ClassB has a foo method' );
    is( $meth->original_method, Role::Bar->meta->get_method('foo'),
        'ClassA->foo was cloned from Role::Bar->foo' );
    is( $meth->original_method->original_method, Role::Foo->meta->get_method('foo'),
        '... which in turn was cloned from Role::Foo->foo' );
    is( $meth->fully_qualified_name, 'ClassB::foo',
        'fq name is ClassA::foo' );
    is( $meth->original_fully_qualified_name, 'Role::Foo::foo',
        'original fq name is Role::Foo::foo' );
} 5;

isnt( ClassA->foo, "ClassB::foo", "ClassA::foo is not confused with ClassB::foo");

{
    local $TODO =
      "multiply-consumed roles' subs take on their most recently used name";
    is( ClassB->foo, 'ClassB::foo', 'ClassB::foo knows its name' );
    is( ClassA->foo, 'ClassA::foo', 'ClassA::foo knows its name' );
}
