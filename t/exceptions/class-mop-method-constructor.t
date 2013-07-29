#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose();

{
    my $exception = exception {
        Class::MOP::Method::Constructor->new( is_inline => 1);
    };

    like(
        $exception,
        qr/\QYou must pass a metaclass instance if you want to inline/,
        "no metaclass is given");

    isa_ok(
        $exception,
        "Moose::Exception::MustSupplyAMetaclass",
        "no metaclass is given");
}

{
    my $exception = exception {
        Class::MOP::Method::Constructor->new;
    };

    like(
        $exception,
        qr/\QYou must supply the package_name and name parameters/,
	"no package_name and name is given");

    isa_ok(
        $exception,
        "Moose::Exception::MustSupplyPackageNameAndName",
	"no package_name and name is given");
}

done_testing;
