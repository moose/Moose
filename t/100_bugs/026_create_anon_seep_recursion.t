#!/usr/bin/perl -w

use strict;
use Test::More tests => 1;
use Test::Exception;
use Moose::Meta::Class;

$SIG{__WARN__} = sub { die if shift =~ /recurs/ };

my $meta;
lives_ok {
  $meta = Moose::Meta::Class->create_anon_class(
    superclasses => [ 'Moose::Object', ],
  );
} 'Class is created successfully';
