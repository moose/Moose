use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
    package Foo::API;
    use Moose::Role;

    requires 'foo';
}

{
    package Foo;
    use Moose::Role;

    has foo => (is => 'ro');

    with 'Foo::API';
}

{
    package Foo::Class;
    use Moose;
    ::is( ::exception { with 'Foo' }, undef, 'requirements are satisfied properly' );
}

{
    package Bar;
    use Moose::Role;

    requires 'baz';

    has bar => (is => 'ro');
}

{
    package Baz;
    use Moose::Role;

    requires 'bar';

    has baz => (is => 'ro');
}

{
    package BarBaz;
    use Moose;

    ::is( ::exception { with qw(Bar Baz) }, undef, 'requirements are satisfied properly' );
}

done_testing;
