#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;

{
  package DepAttr;
  use Moose;

  has x => (
    is  => 'ro',
    isa => 'Int',
    required => 1,
    default  => sub { 2 * $_[0]->y },
  );

  has y => (
    is  => 'ro',
    isa => 'Int',
    required => 1,
    default  => sub { 3 * $_[0]->z },
  );

  has z => (
    is  => 'ro',
    isa => 'Int',
    required => 1,
    default  => sub { 4 * $_[0]->x },
  );
}

dies_ok {
    my $obj = DepAttr->new;
} 'we cannot create an object with attribute dependency loops';

{
  my $obj = DepAttr->new({ z => 1 });;
  isa_ok($obj, 'DepAttr', 'result of ->new({z=>1})');
  is($obj->z, 1, ' ... z = 1');
  is($obj->y, 3, ' ... y = 3');
  is($obj->x, 6, ' ... x = 6');
}

{
  my $obj = DepAttr->new({ x => 1 });;
  isa_ok($obj, 'DepAttr', 'result of ->new({x=>1})');
  is($obj->x,  1, ' ... x = 1');
  is($obj->y, 12, ' ... y = 12');
  is($obj->z,  4, ' ... z = 4');
}
