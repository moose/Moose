#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;

use Moose ();
use Moose::Meta::Class;

use MetaTest;

skip_all_meta 2;

my $meta = Moose::Meta::Class->create('Banana');

my $warn;
$SIG{__WARN__} = sub { $warn = "@_" };

$meta->add_attribute('foo');
like $warn, qr/Attribute \(foo\) of class Banana has no associated methods/,
  'correct error message';

$warn = '';
$meta->add_attribute('bar', is => 'bare');
is $warn, '', 'add attribute with no methods and is => "bare"';
