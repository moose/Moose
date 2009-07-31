#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 8;
use Test::Exception;

# note: not sure about "" and 0 being illegal attribute names
# but I'm just copying what Class::MOP::Attribute does

my $exception_regex = qr/You must provide a name for the attribute/;
{
    package My::Role;
    use Moose::Role;
    ::throws_ok{ has;       } $exception_regex, 'has; fails';
    ::throws_ok{ has undef; } $exception_regex, 'has undef; fails';
    ::throws_ok{ has "";    } $exception_regex, 'has ""; fails';
    ::throws_ok{ has 0;     } $exception_regex, 'has 0; fails';
}

{
    package My::Class;
    use Moose;
    ::throws_ok{ has;       } $exception_regex, 'has; fails';
    ::throws_ok{ has undef; } $exception_regex, 'has undef; fails';
    ::throws_ok{ has "";    } $exception_regex, 'has ""; fails';
    ::throws_ok{ has 0;     } $exception_regex, 'has 0; fails';
}

