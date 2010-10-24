#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

ok ! exception {
    package MooseX::Attribute::Test;
    use Moose::Role;
}, 'creating custom attribute "metarole" is okay';

ok ! exception {
    package Moose::Meta::Attribute::Custom::Test;
    use Moose;

    extends 'Moose::Meta::Attribute';
    with 'MooseX::Attribute::Test';
}, 'custom attribute metaclass extending role is okay';

done_testing;
