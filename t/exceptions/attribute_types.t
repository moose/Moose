#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Moose::Util::TypeConstraints;

# no attribute
my $exception = exception { find_type_constraint('Int')->assert_valid("eek") };
isa_ok($exception, 'Moose::Exception::TypeConstraint');
is($exception->message, q{Validation failed for 'Int' with value "eek"}, 'exception->message');
is($exception->value, "eek", 'exception->value');
is($exception->type_name, "Int", 'exception->type_name');
is($exception->attribute_name, undef, 'exception->attribute_name');

BEGIN {
    package Foo;
    use Moose;

    has count => (
        is => 'rw',
        isa => 'Int',
    );

    has items => (
        traits  => ['Array'],
        is      => 'ro',
        isa     => 'ArrayRef[Int]',
        handles => {
            add_item => 'push',
        },
    );
}

# constructor
$exception = exception { Foo->new(count => "test") };
isa_ok($exception, 'Moose::Exception::TypeConstraint');
is($exception->message, q{Attribute (count) does not pass the type constraint because: Validation failed for 'Int' with value "test"}, 'exception->message');
is($exception->value, "test", 'exception->value');
is($exception->type_name, "Int", 'exception->type_name');
is($exception->attribute_name, "count", 'exception->attribute_name');

# setter
my $value = [];
$exception = exception { Foo->new->count($value) };
isa_ok($exception, 'Moose::Exception::TypeConstraint');
is($exception->message, q{Attribute (count) does not pass the type constraint because: Validation failed for 'Int' with value [  ]}, 'exception->message');
is($exception->value, $value, 'exception->value');
is($exception->type_name, "Int", 'exception->type_name');
is($exception->attribute_name, "count", 'exception->attribute_name');

# native array push
$value = {};
$exception = exception { Foo->new->add_item($value) };
isa_ok($exception, 'Moose::Exception::TypeConstraint');
is($exception->message, q[A new member value for items does not pass its type constraint because: Validation failed for 'Int' with value {  }], 'exception->message');
is($exception->value, $value, 'exception->value');
is($exception->type_name, "Int", 'exception->type_name');
is($exception->attribute_name, "items", 'exception->attribute_name');

done_testing;
