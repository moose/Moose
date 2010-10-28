#!/usr/bin/perl

use strict;
use warnings;

use Test::Exception;
use Test::More;
use Test::Moose qw( with_immutable );

use Test::Requires {
    'Test::Output' => '0.01',
};

{
    package Baz;
    use Moose;
}

with_immutable {
    lives_and {
        stderr_like { Baz->new( x => 42, 'y' ) }
        qr{\QThe new() method for Baz expects a hash reference or a key/value list. You passed an odd number of arguments at t/010_basics/022_buildargs_warning.t line \E\d+},
            'warning when passing an odd number of args to new()';

        stderr_unlike { Baz->new( x => 42, 'y' ) }
        qr{\QOdd number of elements in anonymous hash},
            'we suppress the standard warning from Perl for an odd number of elements in a hash';

        stderr_is { Baz->new( { x => 42 } ) }
        q{},
            'we handle a single hashref to new without errors';
    };
}
'Baz';

done_testing;
