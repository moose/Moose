#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;

BEGIN {
    use_ok('Moose::AttributeHelpers');
}

{
    package Foo;
    use Moose;

    has 'bar' => (is => 'rw');

    package Stuffed::Role;
    use Moose::Role;

    has 'options' => (
        traits    => [ 'Collection::Array' ],
        is        => 'ro',
        isa       => 'ArrayRef[Foo]',
    );

    package Bulkie::Role;
    use Moose::Role;

    has 'stuff' => (
        traits    => [ 'Collection::Array' ],
        is        => 'ro',
        isa       => 'ArrayRef',
        handles   => {
            get_stuff => 'get',
        }
    );

    package Stuff;
    use Moose;

    ::lives_ok {
        with 'Stuffed::Role';
    } '... this should work correctly';

    ::lives_ok {
        with 'Bulkie::Role';
    } '... this should work correctly';

}
