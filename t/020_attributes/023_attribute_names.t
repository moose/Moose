#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Fatal;

my $exception_regex = qr/You must provide a name for the attribute/;
{
    package My::Role;
    use Moose::Role;

    ::like ::exception {
        has;
    }, $exception_regex, 'has; fails';

    ::like ::exception {
        has undef;
    }, $exception_regex, 'has undef; fails';

    ::ok ! ::exception {
        has "" => (
            is => 'bare',
        );
    }, 'has ""; works now';

    ::ok ! ::exception {
        has 0 => (
            is => 'bare',
        );
    }, 'has 0; works now';
}

{
    package My::Class;
    use Moose;

    ::like ::exception {
        has;
    }, $exception_regex, 'has; fails';

    ::like ::exception {
        has undef;
    }, $exception_regex, 'has undef; fails';

    ::ok ! ::exception {
        has "" => (
            is => 'bare',
        );
    }, 'has ""; works now';

    ::ok ! ::exception {
        has 0 => (
            is => 'bare',
        );
    }, 'has 0; works now';
}

done_testing;
