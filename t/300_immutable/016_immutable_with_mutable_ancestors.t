#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use lib 't/lib';

BEGIN {
    eval "use Test::Output;";
    plan skip_all => "Test::Output is required for this test" if $@;
    plan tests => 6;
}

{
    package Foo;
    use Moose;
}

{
    package Foo::Sub;
    use Moose;
    extends 'Foo';

    ::stderr_like {
        __PACKAGE__->meta->make_immutable
    } qr/^Calling make_immutable on Foo::Sub, which has a mutable ancestor \(Foo\)/,
      "warning when making a class with mutable ancestors immutable";
}

Foo->meta->make_immutable;

{
    package Foo::Sub2;
    use Moose;
    extends 'Foo';

    ::stderr_is {
        __PACKAGE__->meta->make_immutable
    } '', "no warning when all ancestors are immutable";
}

{
    package Foo::Sub3;
    use Moose;
    extends 'Foo';
}

{
    package Foo::Sub3::Sub;
    use Moose;
    extends 'Foo::Sub3';
}

{
    package Foo::Sub3::Sub::Sub;
    use Moose;
    extends 'Foo::Sub3::Sub';

    ::stderr_like {
        __PACKAGE__->meta->make_immutable
    } qr/^Calling make_immutable on Foo::Sub3::Sub::Sub, which has a mutable ancestor \(Foo::Sub3::Sub\)/,
      "warning when making a class with mutable ancestors immutable";
}

stderr_like {
    require Recursive::Parent
} qr/^Calling make_immutable on Recursive::Child, which has a mutable ancestor \(Recursive::Parent\)/,
  "circular dependencies via use are caught properly";

{
    package Base::Role;
    use Moose::Role;

    sub foo { 42 }

    package Bar;
    use Moose;
    use Moose::Util::MetaRole;

    Moose::Util::MetaRole::apply_base_class_roles(
        for_class => __PACKAGE__,
        roles     => ['Base::Role'],
    );

    ::stderr_is {
        __PACKAGE__->meta->make_immutable
    } '', "no warning when ancestor is a base-class role subclass of Moose::Object";
}

{
    package Foo::Sub4;
    use Moose;
    extends 'Foo';

    ::stderr_is {
        __PACKAGE__->meta->make_immutable(allow_mutable_ancestors => 1)
    } '',
      "no warning when allow_mutable_ancestors => 1 is passed";
}
