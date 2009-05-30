#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 10;

{
    package FooTrait;
    use Moose::Role;
}
{
    package Foo;
    use Moose -traits => ['FooTrait'];
}

is(Class::MOP::class_of('Foo'), Foo->meta,
    "class_of and ->meta are the same on Foo");
my $meta = Foo->meta;
is(Class::MOP::class_of($meta), $meta->meta,
    "class_of and ->meta are the same on Foo's metaclass");
isa_ok(Class::MOP::class_of($meta), 'Moose::Meta::Class');
isa_ok($meta->meta, 'Moose::Meta::Class');
Foo->meta->make_immutable;
is(Class::MOP::class_of('Foo'), Foo->meta,
    "class_of and ->meta are the same on Foo (immutable)");
$meta = Foo->meta;
isa_ok($meta->meta, 'Moose::Meta::Class');
ok(Class::MOP::class_of($meta)->is_immutable, "metaclass is immutable");
TODO: {
    local $TODO = "immutable metaclasses with traits do weird things";
    is(Class::MOP::class_of($meta), $meta->meta,
        "class_of and ->meta are the same on Foo's metaclass (immutable)");
    isa_ok(Class::MOP::class_of($meta), 'Moose::Meta::Class');
    ok($meta->meta->is_immutable, "metaclass is immutable");
}
