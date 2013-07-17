#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Try::Tiny;

# tests for type/subtype name contain invalid characters
{
    like(
        exception {
            use Moose::Util::TypeConstraints;
            subtype 'Foo-Baz' => as 'Item'
        }, qr/contains invalid characters/,
        "Type names cannot contain a dash (via subtype sugar)");

    isa_ok(
        exception {
            use Moose::Util::TypeConstraints;
            subtype 'Foo-Baz' => as 'Item';
        }, "Moose::Exception::InvalidNameForType",
        "Type names cannot contain a dash (via subtype sugar)");
}

done_testing;