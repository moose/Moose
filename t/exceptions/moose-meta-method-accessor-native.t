#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose();

{
    {
        package Foo;
        use Moose;

        has 'foo' => (
            is      => 'ro',
            isa     => 'Str',
            traits  => ['String'],
            handles => {
                substr => 'substr',
            },
            required => 1
        );
    }

    my $foo_obj = Foo->new( foo => 'hello' );

    my $exception = exception {
        $foo_obj->substr(1,2,3,3);
    };

    like(
        $exception,
        qr/Cannot call substr with more than 3 arguments/,
        "substr doesn't take 4 arguments");

    isa_ok(
        $exception,
        'Moose::Exception::MethodExpectsFewerArgs',
        "substr doesn't take 4 arguments");

    is(
        $exception->method_name,
        "substr",
        "substr doesn't take 4 arguments");

    is(
        $exception->maximum_args,
        3,
        "substr doesn't take 4 arguments");
}

{
    {
        package Bar;
        use Moose;

        has 'foo' => (
            is      => 'ro',
            isa     => 'Str',
            traits  => ['String'],
            handles => {
                substr  => 'substr',
            },
            required => 1
        );
    }

    my $foo_obj = Bar->new( foo => 'hello' );

    my $exception = exception {
        $foo_obj->substr;
    };

    like(
        $exception,
        qr/Cannot call substr without at least 1 argument/,
        "substr expects atleast 1 argument");

    isa_ok(
        $exception,
        'Moose::Exception::MethodExpectsMoreArgs',
        "substr expects atleast 1 argument");

    is(
        $exception->method_name,
        "substr",
        "substr expects atleast 1 argument");

    is(
        $exception->minimum_args,
        1,
        "substr expects atleast 1 argument");
}

{
    {
        package Bar2;
        use Moose;
        with 'Moose::Meta::Method::Accessor::Native::Reader';

        sub _return_value {
            return 1;
        }

        sub _get_value {
            return 1
        }

        sub _inline_store_value {
            return 1;
        }

        sub _eval_environment {
            return 1;
        }
    }

    my $exception = exception {
        Bar2->new( curried_arguments => 'xyz' );
    };

    like(
        $exception,
        qr/You must supply a curried_arguments which is an ARRAY reference/,
        "curried arguments is 'xyz'");

    isa_ok(
        $exception,
        'Moose::Exception::MustSupplyArrayRefAsCurriedArguments',
        "curried arguments is 'xyz'");

    is(
        $exception->class_name,
        "Bar2",
        "curried arguments is 'xyz'");
}

done_testing;
