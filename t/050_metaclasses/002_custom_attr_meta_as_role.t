#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Exception;

use MetaTest;

skip_all_meta 2;

lives_ok {
    package MooseX::Attribute::Test;
    use Moose::Role;
} 'creating custom attribute "metarole" is okay';

lives_ok {
    package Moose::Meta::Attribute::Custom::Test;
    use Moose;

    extends 'Moose::Meta::Attribute';
    with 'MooseX::Attribute::Test';
} 'custom attribute metaclass extending role is okay';
