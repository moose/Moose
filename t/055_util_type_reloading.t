#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib', 'lib';

use Test::More tests => 5;
use Test::Exception;

BEGIN {
	use_ok('Moose');
}

eval { require Foo; };
ok(!$@, '... loaded Foo successfully') || diag $@;

delete $INC{'Foo.pm'};

eval { require Foo; };
ok(!$@, '... re-loaded Foo successfully') || diag $@;

eval { require Bar; };
ok(!$@, '... loaded Bar successfully') || diag $@;

delete $INC{'Bar.pm'};

eval { require Bar; };
ok(!$@, '... re-loaded Bar successfully') || diag $@;