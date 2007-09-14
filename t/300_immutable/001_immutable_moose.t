#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;
use Test::Exception;

BEGIN {
    use_ok('Moose');
    use_ok('Moose::Meta::Role');
}

{
  package FooRole;
  our $VERSION = '0.01';
  sub foo { 'FooRole::foo' }
}

{
  package Foo;
  use Moose;
}

{
  my $foo_role = Moose::Meta::Role->initialize('FooRole');
  my $meta = Foo->meta;
  lives_ok{ $meta->make_immutable       } "Foo is imutable";
  dies_ok{  $meta->add_role($foo_role)  } "Add Role is locked";
  lives_ok{ $meta->make_mutable         } "Foo is mutable";
  lives_ok{ $meta->add_role($foo_role)  } "Add Role is unlocked";
}

{
  package Bar;

  use Moose;

  sub BUILD { 'bar' }
}

{
  package Baz;

  use Moose;

  extends 'Bar';

  sub BUILD { 'baz' }
}

lives_ok { Bar->meta->make_immutable }
  'Immutable meta with single BUILD';

lives_ok { Baz->meta->make_immutable }
  'Immutable meta with multiple BUILDs';

=pod

Nothing here yet, but soon :)

=cut
