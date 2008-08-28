#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Moose::Meta::Class;
use Moose::Util;

use lib 't/lib', 'lib';

plan tests => 1;

my $builder_meta = Moose::Meta::Class->create(
    'YATTA' => (
        superclass => 'Moose::Meta::Class',
        roles      => [ qw( Role::Interface Role::Child ) ],
    )
);

ok 1;

