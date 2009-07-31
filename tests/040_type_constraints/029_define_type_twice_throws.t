#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;

BEGIN {
    use_ok('Moose::Util::TypeConstraints');
}

{
    package Some::Class;
    use Moose::Util::TypeConstraints;

    subtype 'MySubType' => as 'Int' => where { 1 };
}

throws_ok {
    package Some::Other::Class;
    use Moose::Util::TypeConstraints;

    subtype 'MySubType' => as 'Int' => where { 1 };
} qr/cannot be created again/, 'Trying to create same type twice throws';

