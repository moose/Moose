#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use Moose ();
use Moose::Meta::Class;

my $meta = Moose::Meta::Class->create_anon_class;

#local $TODO = 'not implemented yet';

eval { $meta->add_attribute('foo') };
like $@, qr/Attribute \(foo\) has no associated methods/,
  'correct error message';

ok(
    eval { $meta->add_attribute('bar', is => 'bare'); 1 },
    'add attribute with no methods',
) or diag $@;
