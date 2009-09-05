#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 6;
use Test::Exception;

use MetaTest;

# this is so that when we use base 'Foo' below we won't get the Foo.pm in t/lib
BEGIN {
   @INC = grep { $_ ne 't/lib' } @INC;
};



=pod

This test demonstrates that Moose will respect
a previously set @ISA using use base, and not
try to add Moose::Object to it.

However, this is extremely order sensitive as
this test also demonstrates.

=cut

{
    package Foo;
    use strict;
    use warnings;

    sub foo { 'Foo::foo' }

    package Bar;
    use base 'Foo';
    use Moose;

    sub new { (shift)->meta->new_object(@_) }

    package Baz;
    use Moose;
    use base 'Foo';
}

skip_meta {
   my $bar = Bar->new;
   isa_ok($bar, 'Bar');
   isa_ok($bar, 'Foo');
   ok(!$bar->isa('Moose::Object'), '... Bar is not Moose::Object subclass');
} 3;

my $baz = Baz->new;
isa_ok($baz, 'Baz');
isa_ok($baz, 'Foo');
isa_ok($baz, 'Moose::Object');

