#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    package Test::Dog;
    use Moose::Role;

    sub bark { "dog" }
}

BEGIN {
    package Test::Tree;
    use Moose::Role;

    sub bark { "tree" }
}

my $exception = exception {
    package C;
    use Moose;

    with 'Test::Dog', 'Test::Tree';
};

isa_ok($exception, 'Moose::Exception::MethodConflict');
is($exception->message, q{Due to a method name conflict in roles 'Test::Dog' and 'Test::Tree', the method 'bark' must be implemented or excluded by 'C'});
is($exception->consumer->name, 'C', 'consumer');
is((join ', ', sort $exception->roles), ('Test::Dog, Test::Tree'), 'roles');
is((join ', ', sort $exception->methods), ('bark'), 'methods');

done_testing;

