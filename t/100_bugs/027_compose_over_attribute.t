use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;

{
    package BaseRole;
    use Moose::Role;
    has foo => (is => 'ro');
}

TODO: {
    local $TODO = '+attributes in roles that compose over other roles';

    eval q{
        package ChildRole;
        use Moose::Role;
        with 'BaseRole';
        has '+foo' => (default => 'bar');

        package AClass;
        use Moose;
        with 'ChildRole';
    };

    ok( (not $@), '+attribute created in child role' );

    is eval{ AClass->new->foo }, 'bar',
        '+attribute in child role works correctly';
}
