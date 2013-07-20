#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Try::Tiny;

use Moose::Util::TypeConstraints;
use Class::MOP::Attribute;

{
    my $exception =  exception {
	my $class = Class::MOP::Attribute->new;
    };

    like(
        $exception,
        qr/You must provide a name for the attribute/,
        "no attribute name given to new");

    isa_ok(
        $exception,
        "Moose::Exception::MOPAttributeNewNeedsAttributeName",
        "no attribute name given to new");
}

done_testing;