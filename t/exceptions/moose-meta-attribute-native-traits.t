#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose;

{
    my $exception = exception {
        {
            package TestClass;
            use Moose;

            has 'foo' => (
                traits => ['Array'],
                is     => 'ro',
                isa    => 'Int'
            );
        }
    };

    like(
        $exception,
        qr/The type constraint for foo must be a subtype of ArrayRef but it's a Int/,
        "isa is given as Int, but it should be ArrayRef");

    isa_ok(
        $exception,
        'Moose::Exception::WrongTypeConstraintGiven',
        "isa is given as Int, but it should be ArrayRef");

    is(
        $exception->required_type,
        "ArrayRef",
        "isa is given as Int, but it should be ArrayRef");

    is(
        $exception->given_type,
        "Int",
        "isa is given as Int, but it should be ArrayRef");

    is(
        $exception->attribute_name,
        "foo",
        "isa is given as Int, but it should be ArrayRef");
}

{
    my $exception = exception {
        {
            package TestClass2;
            use Moose;

            has 'foo' => (
                traits  => ['Array'],
                is      => 'ro',
                isa     => 'ArrayRef',
                handles => 'bar'
            );
        }
    };

    like(
        $exception,
        qr/The 'handles' option must be a HASH reference, not bar/,
        "'bar' is given as handles");

    isa_ok(
        $exception,
        'Moose::Exception::HandlesMustBeAHashRef',
        "'bar' is given as handles");

    is(
        $exception->given_handles,
        "bar",
        "'bar' is given as handles");
}

{
    my $exception = exception {
        {
            package TraitTest;
            use Moose::Role;
            with 'Moose::Meta::Attribute::Native::Trait';

            sub _helper_type { "ArrayRef" }
        }

        {
            package TestClass3;
            use Moose;

            has 'foo' => (
                traits  => ['TraitTest'],
                is      => 'ro',
                isa     => 'ArrayRef',
                handles => { get_count => 'count' }
            );
        }
    };

    like(
        $exception,
        qr/\QCannot calculate native type for Moose::Meta::Class::__ANON__::SERIAL::/,
        "cannot calculate native type for the given trait");

    isa_ok(
        $exception,
        'Moose::Exception::CannotCalculateNativeType',
        "cannot calculate native type for the given trait");
}

{
    my $regex = qr/bar/;
    my $exception = exception {
        {
            package TestClass4;
            use Moose;

            has 'foo' => (
                traits  => ['Array'],
                is      => 'ro',
                isa     => 'ArrayRef',
                handles => { get_count => $regex }
            );
        }
    };

    like(
        $exception,
        qr/\QAll values passed to handles must be strings or ARRAY references, not $regex/,
        "a Regexp is given to handles");

    isa_ok(
        $exception,
        'Moose::Exception::InvalidHandleValue',
        "a Regexp is given to handles");

    is(
        $exception->handle_value,
        $regex,
        "a Regexp is given to handles");
}

done_testing;
