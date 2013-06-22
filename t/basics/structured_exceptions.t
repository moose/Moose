#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Try::Tiny;

{
    like(
        exception {
            package SubClassNoSuperClass;
            use Moose;
            extends;
        }, qr/Must derive at least one class/,
        "extends requires at least one argument");

    isa_ok(
        exception {
            package SubClassNoSuperClass;
            use Moose;
            extends;
        }, 'Moose::Exception::ExtendsMissingArgs',
        "extends requires at least one argument");
}

{
    like(
        exception {
            package ClassConsumingClass;
            use Moose;
            use DateTime;
            with 'DateTime';
        }, qr/You can only consume roles, DateTime is not a Moose role/,
        "You can't consume a class");

    isa_ok(
        exception {
            package ClassConsumingClass;
            use Moose;
            use DateTime;
            with 'DateTime';
	}, 'Moose::Exception::CanOnlyConsumeRole',
        "You can't consume a class");

    like(
        exception {
            package foo;
            use Moose;
	    use DateTime;
            with 'Not::A::Real::Package';
        }, qr!Can't locate Not/A/Real/Package\.pm!,
        "You can't consume a class which doesn't exist");

    like(
        exception {
            package foo;
            use Moose;
	    use DateTime;
            with sub {};
        }, qr/argument is not a module name/,
        "You can only consume a module");
}

done_testing;
