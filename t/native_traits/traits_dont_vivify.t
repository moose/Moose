#!/usr/bin/env perl

use Test::More;

package TestClass;
  use Moose;
  has hash => (is => 'ro', isa => 'HashRef', traits => [ 'Hash' ], handles => {
    hash_count => 'count',
    hash_keys => 'keys',
    hash_exists => 'exists',
    hash_defined => 'defined',
    hash_values => 'values',
    hash_kv => 'kv',
    hash_elements => 'elements',
    hash_is_empty => 'is_empty',
  });
  has bool => (is => 'ro', isa => 'Bool', traits => [ 'Bool' ], handles => {
    not_bool => 'not',
  });
  has array => (is => 'ro', isa => 'ArrayRef', traits => [ 'Array' ], handles => {
    array_count => 'count',
    array_is_empty => 'is_empty',
    array_elements => 'elements',
    array_get => 'get',
    array_accessor => 'accessor',
    array_grep => 'grep',
    array_map => 'map',
    array_reduce => 'reduce',
  });

package main;

# Hash
foreach my $method ('hash_count', 'hash_keys', 'hash_values',
                    'hash_kv', 'hash_elements', 'hash_is_empty') {
  my $instance = TestClass->new;
  #ok(not(defined $instance->hash), 'hash is undefined');
  $instance->$method;
  ok(not(defined $instance->hash), 'hash is still undefined');
}

{
  my $instance = TestClass->new;
  #ok(not(defined $instance->hash), 'hash is undefined');
  $instance->hash_exists('randomkey');
  ok(not(defined $instance->hash), 'hash is still undefined');
}

{
  my $instance = TestClass->new;
  #ok(not(defined $instance->hash), 'hash is undefined');
  $instance->hash_defined('randomkey');
  ok(not(defined $instance->hash), 'hash is still undefined');
}

# Bool
{
  my $instance = TestClass->new;
  #ok(not(defined $instance->bool), 'bool is undefined');
  $instance->not_bool;
  ok(not(defined $instance->bool), 'bool is still undefined');
}

# Array
foreach my $method ('array_count', 'array_is_empty', 'array_elements') {
  my $instance = TestClass->new;
  #ok(not(defined $instance->array), 'array is undefined');
  $instance->$method;
  ok(not(defined $instance->array), 'array is still undefined');
}

{
  my $instance = TestClass->new;
  #ok(not(defined $instance->array), 'array is undefined');
  $instance->array_get(1);
  ok(not(defined $instance->array), 'array is still undefined');
}

{
  my $instance = TestClass->new;
  #ok(not(defined $instance->array), 'array is undefined');
  $instance->array_accessor(1);
  ok(not(defined $instance->array), 'array is still undefined');
}

{
  my $instance = TestClass->new;
  #ok(not(defined $instance->array), 'array is undefined');
  $instance->array_grep(sub { 1 });
  ok(not(defined $instance->array), 'array is still undefined');
}

{
  my $instance = TestClass->new;
  #ok(not(defined $instance->array), 'array is undefined');
  $instance->array_map(sub { 1 });
  ok(not(defined $instance->array), 'array is still undefined');
}

{
  my $instance = TestClass->new;
  #ok(not(defined $instance->array), 'array is undefined');
  $instance->array_reduce(sub { $_[0] . $_[1] });
  ok(not(defined $instance->array), 'array is still undefined');
}

done_testing;
