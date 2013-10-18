#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose();

{
    my $exception =  exception {
        my $method = Moose::Meta::Method::Constructor->new( options => (1,2,3));
    };

    like(
        $exception,
        qr/You must pass a hash of options/,
	"options is not a HASH ref");

    isa_ok(
        $exception,
        "Moose::Exception::MustPassAHashOfOptions",
	"options is not a HASH ref");
}

{
    my $exception =  exception {
        my $method = Moose::Meta::Method::Constructor->new( options => {});
    };

    like(
        $exception,
        qr/You must supply the package_name and name parameters/,
	"package_name and name are not given");

    isa_ok(
        $exception,
        "Moose::Exception::MustSupplyPackageNameAndName",
	"package_name and name are not given");
}

done_testing;
