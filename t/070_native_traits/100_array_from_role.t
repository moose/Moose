#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

{
    package Foo;
    use Moose;

    has 'bar' => ( is => 'rw' );

    package Stuffed::Role;
    use Moose::Role;

    has 'options' => (
        traits => ['Array'],
        is     => 'ro',
        isa    => 'ArrayRef[Foo]',
    );

    package Bulkie::Role;
    use Moose::Role;

    has 'stuff' => (
        traits  => ['Array'],
        is      => 'ro',
        isa     => 'ArrayRef',
        handles => {
            get_stuff => 'get',
        }
    );

    package Stuff;
    use Moose;

    ::lives_ok{ with 'Stuffed::Role';
        } '... this should work correctly';

    ::lives_ok{ with 'Bulkie::Role';
        } '... this should work correctly';
}

done_testing;
