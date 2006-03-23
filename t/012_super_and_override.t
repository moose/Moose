#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

BEGIN {
    use_ok('Moose');           
}

{
    package Foo;
    use strict;
    use warnings;
    use Moose;
    
    sub foo { 'Foo::foo' }
    sub bar { 'Foo::bar' }    
    sub baz { 'Foo::baz' }
    
    package Bar;
    use strict;
    use warnings;
    use Moose;
    
    extends 'Foo';
    
    override bar => sub { 'Bar::bar -> ' . super() };   
    
    package Baz;
    use strict;
    use warnings;
    use Moose;
    
    extends 'Bar';
    
    override baz => sub { 'Baz::baz -> ' . super() }; 
}

my $baz = Baz->new();
isa_ok($baz, 'Baz');
isa_ok($baz, 'Bar');
isa_ok($baz, 'Foo');

is($baz->foo(), 'Foo::foo', '... got the right value from &foo');
is($baz->bar(), 'Bar::bar -> Foo::bar', '... got the right value from &bar');
is($baz->baz(), 'Baz::baz -> Foo::baz', '... got the right value from &baz');
