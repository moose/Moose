#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose();

{
    {
        package Foo;
        use Moose::Role;
    }

    my $exception = exception {
        Foo->meta->has_method;
    };

    like(
        $exception,
        qr/\QYou must define a method name/,
        "no method name is given");

    isa_ok(
        $exception,
        "Moose::Exception::MustDefineAMethodName",
        "no method name is given");

    is(
        $exception->instance,
        Foo->meta,
        "no method name is given");
}

{
    {
        package Foo;
        use Moose::Role;
    }

    my $exception = exception {
        Foo->meta->add_method;
    };

    like(
        $exception,
        qr/\QYou must define a method name/,
        "no method name is given");

    isa_ok(
        $exception,
        "Moose::Exception::MustDefineAMethodName",
        "no method name is given");

    is(
        $exception->instance,
        Foo->meta,
        "no method name is given");
}

{
    {
        package Foo;
        use Moose::Role;
    }

    my $exception = exception {
        Foo->meta->get_method;
    };

    like(
        $exception,
        qr/\QYou must define a method name/,
        "no method name is given");

    isa_ok(
        $exception,
        "Moose::Exception::MustDefineAMethodName",
        "no method name is given");

    is(
        $exception->instance,
        Foo->meta,
        "no method name is given");
}

{
    {
        package Foo;
        use Moose::Role;
    }

    my $exception = exception {
        Foo->meta->remove_method;
    };

    like(
        $exception,
        qr/\QYou must define a method name/,
        "no method name is given");

    isa_ok(
        $exception,
        "Moose::Exception::MustDefineAMethodName",
        "no method name is given");

    is(
        $exception->instance,
        Foo->meta,
        "no method name is given");
}

{
    {
        package Bar::Role;
        use Moose::Role;
    }

    my $meta = Bar::Role->meta;

    my $exception = exception {
        $meta->wrap_method_body;
    };

    like(
        $exception,
        qr/Your code block must be a CODE reference/,
        "no arguments passed to wrap_method_body");

    isa_ok(
        $exception,
        "Moose::Exception::CodeBlockMustBeACodeRef",
        "no arguments passed to wrap_method_body");

    is(
        $exception->instance,
        $meta,
        "no arguments passed to wrap_method_body");
}

done_testing;
