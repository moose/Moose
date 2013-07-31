#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose();

{
    my $exception =  exception {
        package Foo;
        use Moose;
    
        augment 'foo' => sub {};
    };

    like(
        $exception,
        qr/You cannot augment 'foo' because it has no super method/,
        "'Foo' has no super class");

    isa_ok(
        $exception,
        "Moose::Exception::CannotAugmentNoSuperMethod",
        "'Foo' has no super class");

    is(
        $exception->method_name,
        'foo',
        "'Foo' has no super class");	
}

done_testing;
