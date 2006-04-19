#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;

BEGIN {
    use_ok('Moose');           
}

{
    package Foo;
    use strict;
    use warnings;
    
    sub foo { 'Foo::foo' }
    
    package Bar;
    use strict;
    use warnings;
    use Moose;
    
    use base 'Foo';
}

my $bar = Bar->new;
isa_ok($bar, 'Bar');
isa_ok($bar, 'Foo');