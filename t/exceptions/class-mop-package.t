#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose();

{
    my $exception = exception {
        Class::MOP::Package->reinitialize;
    };

    like(
        $exception,
        qr/\QYou must pass a package name or an existing Class::MOP::Package instance/,
        "no package name is given");

    isa_ok(
        $exception,
        "Moose::Exception::MustPassAPackageNameOrAnExistingClassMOPPackageInstance",
        "no package name is given");
}

{
    my $exception = exception {
        Class::MOP::Package->create_anon(cache => 1);
    };

    like(
        $exception,
        qr/Packages are not cacheable/,
        "can't cache anon packages");

    isa_ok(
        $exception,
        "Moose::Exception::PackagesAndModulesAreNotCachable",
        "can't cache anon packages");
}

done_testing;
