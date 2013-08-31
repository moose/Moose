#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose();

{
    package Foo;
    use Moose;

    has 'foo' => (
	is       => 'ro',
	isa      => 'ArrayRef',
	traits   => ['Array'],
	handles  => {
	    get           => 'get',
            first         => 'first',
            first_index   => 'first_index',
            grep          => 'grep',
            join          => 'join',
            map           => 'map',
	    natatime      => 'natatime',
            reduce        => 'reduce',
            sort          => 'sort',
            sort_in_place => 'sort_in_place',
            splice        => 'splice'
	},
	required => 1
	);
}

my $foo_obj;

{

    my $foo_obj = Foo->new( foo => [1, 2, 3] );
    my $exception = exception { 
        $foo_obj->get(1.1);
    };

    like(
        $exception,
        qr/The index passed to get must be an integer/,
        "get takes integer argument");

    isa_ok(
        $exception,
        'Moose::Exception::InvalidArgumentToMethod',
        "get takes integer argument");

    is(
        $exception->argument,
        1.1,
        "get takes integer argument");

    is(
        $exception->method_name,
	"get",
        "get takes integer argument");
}

{
    $foo_obj = Foo->new( foo => [1, 2, 3] );
    my $arg = [12];

    my $exception = exception {
        $foo_obj->first( $arg );
    };

    like(
        $exception,
        qr/The argument passed to first must be a code reference/,
        "an ArrayRef passed to first");

    isa_ok(
        $exception,
        'Moose::Exception::InvalidArgumentToMethod',
        "an ArrayRef passed to first");

    is(
        $exception->method_name,
        "first",
        "an ArrayRef passed to first");

    is(
        $exception->argument,
        $arg,
        "an ArrayRef passed to first");

    is(
        $exception->type_of_argument,
        "code reference",
        "an ArrayRef passed to first");

    is(
        $exception->type,
        "CodeRef",
        "an ArrayRef passed to first");
}

{
    $foo_obj = Foo->new( foo => [1, 2, 3] );
    my $arg = [12];

    my $exception = exception {
        $foo_obj->first_index( $arg );
    };

    like(
        $exception,
        qr/The argument passed to first_index must be a code reference/,
        "an ArrayRef passed to first_index");

    isa_ok(
        $exception,
        'Moose::Exception::InvalidArgumentToMethod',
        "an ArrayRef passed to first_index");

    is(
        $exception->method_name,
        "first_index",
        "an ArrayRef passed to first_index");

    is(
        $exception->argument,
        $arg,
        "an ArrayRef passed to first_index");

    is(
        $exception->type_of_argument,
        "code reference",
        "an ArrayRef passed to first_index");

    is(
        $exception->type,
        "CodeRef",
        "an ArrayRef passed to first_index");
}

{
    $foo_obj = Foo->new( foo => [1, 2, 3] );
    my $arg = [12];

    my $exception = exception {
        $foo_obj->grep( $arg );
    };

    like(
        $exception,
        qr/The argument passed to grep must be a code reference/,
        "an ArrayRef passed to grep");

    isa_ok(
        $exception,
        'Moose::Exception::InvalidArgumentToMethod',
        "an ArrayRef passed to grep");

    is(
        $exception->method_name,
        "grep",
        "an ArrayRef passed to grep");

    is(
        $exception->argument,
        $arg,
        "an ArrayRef passed to grep");

    is(
        $exception->type_of_argument,
        "code reference",
        "an ArrayRef passed to grep");

    is(
        $exception->type,
        "CodeRef",
        "an ArrayRef passed to grep");
}

{
    $foo_obj = Foo->new( foo => [1, 2, 3] );
    my $arg = [12];

    my $exception = exception {
        $foo_obj->join( $arg );
    };

    like(
        $exception,
        qr/The argument passed to join must be a string/,
        "an ArrayRef passed to join");

    isa_ok(
        $exception,
        'Moose::Exception::InvalidArgumentToMethod',
        "an ArrayRef passed to join");

    is(
        $exception->method_name,
        "join",
        "an ArrayRef passed to join");

    is(
        $exception->argument,
        $arg,
        "an ArrayRef passed to join");

    is(
        $exception->type_of_argument,
        "string",
        "an ArrayRef passed to join");

    is(
        $exception->type,
        "Str",
        "an ArrayRef passed to join");
}

{
    $foo_obj = Foo->new( foo => [1, 2, 3] );
    my $arg = [12];

    my $exception = exception {
        $foo_obj->map( $arg );
    };

    like(
        $exception,
        qr/The argument passed to map must be a code reference/,
        "an ArrayRef passed to map");

    isa_ok(
        $exception,
        'Moose::Exception::InvalidArgumentToMethod',
        "an ArrayRef passed to map");

    is(
        $exception->method_name,
        "map",
        "an ArrayRef passed to map");

    is(
        $exception->argument,
        $arg,
        "an ArrayRef passed to map");

    is(
        $exception->type_of_argument,
        "code reference",
        "an ArrayRef passed to map");

    is(
        $exception->type,
        "CodeRef",
        "an ArrayRef passed to map");
}

{
    $foo_obj = Foo->new( foo => [1, 2, 3] );
    my $arg = [12];

    my $exception = exception {
        $foo_obj->natatime( $arg );
    };

    like(
        $exception,
        qr/The n value passed to natatime must be an integer/,
        "an ArrayRef passed to natatime");

    isa_ok(
        $exception,
        'Moose::Exception::InvalidArgumentToMethod',
        "an ArrayRef passed to natatime");

    is(
        $exception->method_name,
        "natatime",
        "an ArrayRef passed to natatime");

    is(
        $exception->argument,
        $arg,
        "an ArrayRef passed to natatime");

    is(
        $exception->type_of_argument,
        "integer",
        "an ArrayRef passed to natatime");

    is(
        $exception->type,
        "Int",
        "an ArrayRef passed to natatime");

    $exception = exception {
        $foo_obj->natatime( 1, $arg );
    };

    like(
        $exception,
        qr/The second argument passed to natatime must be a code reference/,
        "an ArrayRef passed to natatime");

    isa_ok(
        $exception,
        'Moose::Exception::InvalidArgumentToMethod',
        "an ArrayRef passed to natatime");

    is(
        $exception->method_name,
        "natatime",
        "an ArrayRef passed to natatime");

    is(
        $exception->argument,
        $arg,
        "an ArrayRef passed to natatime");

    is(
        $exception->type_of_argument,
        "code reference",
        "an ArrayRef passed to natatime");

    is(
        $exception->type,
        "CodeRef",
        "an ArrayRef passed to natatime");
}

{
    $foo_obj = Foo->new( foo => [1, 2, 3] );
    my $arg = [12];

    my $exception = exception {
        $foo_obj->reduce( $arg );
    };

    like(
        $exception,
        qr/The argument passed to reduce must be a code reference/,
        "an ArrayRef passed to reduce");

    isa_ok(
        $exception,
        'Moose::Exception::InvalidArgumentToMethod',
        "an ArrayRef passed to reduce");

    is(
        $exception->method_name,
        "reduce",
        "an ArrayRef passed to reduce");

    is(
        $exception->argument,
        $arg,
        "an ArrayRef passed to reduce");

    is(
        $exception->type_of_argument,
        "code reference",
        "an ArrayRef passed to reduce");

    is(
        $exception->type,
        "CodeRef",
        "an ArrayRef passed to reduce");
}

{
    $foo_obj = Foo->new( foo => [1, 2, 3] );
    my $arg = [12];

    my $exception = exception {
        $foo_obj->sort( $arg );
    };

    like(
        $exception,
        qr/The argument passed to sort must be a code reference/,
        "an ArrayRef passed to sort");

    isa_ok(
        $exception,
        'Moose::Exception::InvalidArgumentToMethod',
        "an ArrayRef passed to sort");

    is(
        $exception->method_name,
        "sort",
        "an ArrayRef passed to sort");

    is(
        $exception->argument,
        $arg,
        "an ArrayRef passed to sort");

    is(
        $exception->type_of_argument,
        "code reference",
        "an ArrayRef passed to sort");

    is(
        $exception->type,
        "CodeRef",
        "an ArrayRef passed to sort");
}

{
    $foo_obj = Foo->new( foo => [1, 2, 3] );
    my $arg = [12];

    my $exception = exception {
        $foo_obj->sort_in_place( $arg );
    };

    like(
        $exception,
        qr/The argument passed to sort_in_place must be a code reference/,
        "an ArrayRef passed to sort_in_place");

    isa_ok(
        $exception,
        'Moose::Exception::InvalidArgumentToMethod',
        "an ArrayRef passed to sort_in_place");

    is(
        $exception->method_name,
        "sort_in_place",
        "an ArrayRef passed to sort_in_place");

    is(
        $exception->argument,
        $arg,
        "an ArrayRef passed to sort_in_place");

    is(
        $exception->type_of_argument,
        "code reference",
        "an ArrayRef passed to sort_in_place");

    is(
        $exception->type,
        "CodeRef",
        "an ArrayRef passed to sort_in_place");
}

{
    $foo_obj = Foo->new( foo => [1, 2, 3] );
    my $arg = [12];

    my $exception = exception {
        $foo_obj->splice( 1, $arg );
    };

    like(
        $exception,
        qr/The length argument passed to splice must be an integer/,
        "an ArrayRef passed to splice");

    isa_ok(
        $exception,
        'Moose::Exception::InvalidArgumentToMethod',
        "an ArrayRef passed to splice");

    is(
        $exception->method_name,
        "splice",
        "an ArrayRef passed to splice");

    is(
        $exception->argument,
        $arg,
        "an ArrayRef passed to splice");

    is(
        $exception->type_of_argument,
        "integer",
        "an ArrayRef passed to splice");

    is(
        $exception->type,
        "Int",
        "an ArrayRef passed to splice");
}

done_testing;
