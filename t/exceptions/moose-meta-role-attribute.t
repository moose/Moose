#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose();

{
    my $exception = exception {
        Moose::Meta::Role::Attribute->new;
    };

    like(
        $exception,
        qr/You must provide a name for the attribute/,
	"no name is given");

    isa_ok(
        $exception,
        "Moose::Exception::MustProvideANameForTheAttribute",
	"no name is given");
}

{
    my $exception = exception {
        Moose::Meta::Role::Attribute->attach_to_role;
    };

    like(
        $exception,
        qr/\QYou must pass a Moose::Meta::Role instance (or a subclass)/,
        "no role is given to attach_to_role");

    isa_ok(
        $exception,
        "Moose::Exception::MustPassAMooseMetaRoleInstanceOrSubclass",
        "no role is given to attach_to_role");
}

done_testing;
