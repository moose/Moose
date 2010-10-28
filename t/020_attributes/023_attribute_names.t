#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $exception_regex = qr/You must provide a name for the attribute/;
{
    package My::Role;
    use Moose::Role;

    ::throws_ok {
        has;
    } $exception_regex, 'has; fails';

    ::throws_ok {
        has undef;
    } $exception_regex, 'has undef; fails';

    ::lives_ok {
        has "" => (
            is => 'bare',
        );
    } 'has ""; works now';

    ::lives_ok {
        has 0 => (
            is => 'bare',
        );
    } 'has 0; works now';
}

{
    package My::Class;
    use Moose;

    ::throws_ok {
        has;
    } $exception_regex, 'has; fails';

    ::throws_ok {
        has undef;
    } $exception_regex, 'has undef; fails';

    ::lives_ok {
        has "" => (
            is => 'bare',
        );
    } 'has ""; works now';

    ::lives_ok {
        has 0 => (
            is => 'bare',
        );
    } 'has 0; works now';
}

done_testing;
