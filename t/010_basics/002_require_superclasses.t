#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib', 'lib';

use Test::More;
use Test::Exception;


{

    package Bar;
    use Moose;

    ::lives_ok { extends 'Foo' } 'loaded Foo superclass correctly';
}

{

    package Baz;
    use Moose;

    ::lives_ok { extends 'Bar' } 'loaded (inline) Bar superclass correctly';
}

{

    package Foo::Bar;
    use Moose;

    ::lives_ok { extends 'Foo', 'Bar' }
    'loaded Foo and (inline) Bar superclass correctly';
}

{

    package Bling;
    use Moose;

    ::throws_ok { extends 'No::Class' }
    qr{Can't locate No/Class\.pm in \@INC},
    'correct error when superclass could not be found';
}

done_testing;
