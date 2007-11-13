#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 14;
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

  #two checks because the inlined methods are different when
  #there is a TC present.
  has 'foos' => (is => 'ro', lazy_build => 1);
  has 'bars' => (isa => 'Str', is => 'ro', lazy_build => 1);
  sub _build_foos{ "many foos" }
  sub _build_bars{ "many bars" }
}

{
  my $foo_role = Moose::Meta::Role->initialize('FooRole');
  my $meta = Foo->meta;

  lives_ok{ Foo->new                    } "lazy_build works";
  is(Foo->new->foos, 'many foos'        , "correct value for 'foos'");
  is(Foo->new->bars, 'many bars'        , "correct value for 'bars'");
  lives_ok{ $meta->make_immutable       } "Foo is imutable";
  dies_ok{  $meta->add_role($foo_role)  } "Add Role is locked";
  lives_ok{ Foo->new                    } "Inlined constructor works with lazy_build";
  is(Foo->new->foos, 'many foos'        , "correct value for 'foos'");
  is(Foo->new->bars, 'many bars'        , "correct value for 'bars'");
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
