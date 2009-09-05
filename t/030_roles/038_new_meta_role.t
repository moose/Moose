#!/usr/bin/env perl
use strict;
use warnings;

use lib 't/lib';

use Test::More;

use MetaTest;

skip_all_meta 1;

do {
    package My::Meta::Role;
    use Moose;
    BEGIN { extends 'Moose::Meta::Role' };
};

do {
    package My::Role;
    use Moose::Role -metaclass => 'My::Meta::Role';
};

is(My::Role->meta->meta->name, 'My::Meta::Role');

