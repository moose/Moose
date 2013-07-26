#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose();

{
    my $exception =  exception {
	Class::MOP::Method->wrap( "foo", ( name => "Bar"));
    };

    like(
        $exception,
        qr/\QYou must supply a CODE reference to bless, not (foo)/,
	"first argument to wrap should be a CODE ref");

    isa_ok(
        $exception,
        "Moose::Exception::WrapTakesACodeRefToBless",
	"first argument to wrap should be a CODE ref");
}

{
    my $exception =  exception {
	Class::MOP::Method->wrap( sub { "foo" }, ());
    };

    like(
        $exception,
        qr/You must supply the package_name and name parameters/,
	"no package name is given to wrap");

    isa_ok(
        $exception,
        "Moose::Exception::PackageNameAndNameParamsNotGivenToWrap",
	"no package name is given to wrap");
}

done_testing;
