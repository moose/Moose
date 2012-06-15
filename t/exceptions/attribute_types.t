#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Moose::Util::TypeConstraints;

BEGIN {
    package Foo;
    use Moose;

    has count => (
        is => 'rw',
        isa => 'Int',
    );
}

my $exception = exception { Foo->new(count => "test") };
isa_ok($exception, 'Moose::Exception::TypeConstraint');
is($exception->message, q{Attribute (count) does not pass the type constraint because: Validation failed for 'Int' with value "test"}, 'exception->message');
is($exception->value, "test", 'exception->value');
is($exception->type_name, "Int", 'exception->type_name');
is($exception->attribute_name, "count", 'exception->attribute_name');

my $value = [];
$exception = exception { Foo->new->count($value) };
isa_ok($exception, 'Moose::Exception::TypeConstraint');
is($exception->message, q{Attribute (count) does not pass the type constraint because: Validation failed for 'Int' with value [  ]}, 'exception->message');
is($exception->value, $value, 'exception->value');
is($exception->type_name, "Int", 'exception->type_name');
is($exception->attribute_name, "count", 'exception->attribute_name');

$exception = exception { find_type_constraint('Int')->assert_valid("eek") };
isa_ok($exception, 'Moose::Exception::TypeConstraint');
is($exception->message, q{Validation failed for 'Int' with value "eek"}, 'exception->message');
is($exception->value, "eek", 'exception->value');
is($exception->type_name, "Int", 'exception->type_name');
is($exception->attribute_name, undef, 'exception->attribute_name');

done_testing;
