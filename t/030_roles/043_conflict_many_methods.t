#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;

{
    package Bomb;
    use Moose::Role;

    sub fuse { }
    sub explode { }

    package Spouse;
    use Moose::Role;

    sub fuse { }
    sub explode { }

    package Caninish;
    use Moose::Role;

    sub bark { }

    package Treeve;
    use Moose::Role;

    sub bark { }
}

package PracticalJoke;
use Moose;

::throws_ok {
    with 'Bomb', 'Spouse';
} qr/Due to method name conflicts in roles 'Bomb' and 'Spouse', the methods 'explode' and 'fuse' must be implemented or excluded by 'PracticalJoke'/;

::throws_ok {
    with (
        'Bomb', 'Spouse',
        'Caninish', 'Treeve',
    );
} qr/Due to method name conflicts in roles 'Bomb' and 'Spouse', the methods 'explode' and 'fuse' must be implemented or excluded by 'PracticalJoke'/;

