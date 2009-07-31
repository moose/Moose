#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;

do {
    package My::Meta::Class;
    use Moose;
    BEGIN { extends 'Moose::Meta::Class' };
};

do {
    package My::Class;
    use Moose -metaclass => 'My::Meta::Class';
};

is(My::Class->meta->meta->name, 'My::Meta::Class');

