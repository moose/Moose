#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose();

{
    package Bar;
    use Moose;
    
    has 'foo' => (
	is      => 'rw',
	isa     => 'ArrayRef[Int]',
	traits  => ['Array'],
	handles => { push => 'push'}
	);
}

my $bar_obj = Bar->new;
{
    my $exception = exception {
        $bar_obj->push(1.2);
    };

    like(
        $exception,
        qr/A new member value for foo does not pass its type constraint because: Validation failed for 'Int' with value 1.2/,
        "trying to push a Float(1.2) to ArrayRef[Int]");

    isa_ok(
        $exception,
        'Moose::Exception::ValidationFailedForInlineTypeConstraint',
        "trying to push a Float(1.2) to ArrayRef[Int]");

    is(
        $exception->attribute_name,
        "foo",
        "trying to push a Float(1.2) to ArrayRef[Int]");

    is(
        $exception->class_name,
        "Bar",
        "trying to push a Float(1.2) to ArrayRef[Int]");

    is(
        $exception->value,
        1.2,
        "trying to push a Float(1.2) to ArrayRef[Int]");
}

done_testing;
