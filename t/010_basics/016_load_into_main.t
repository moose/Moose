#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;

lives_ok {
    eval 'use Moose';
} "export to main";

isa_ok( main->meta, "Moose::Meta::Class" );

isa_ok( main->new, "main");
isa_ok( main->new, "Moose::Object" );

