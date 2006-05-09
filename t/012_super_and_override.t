#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 17;
use Test::Exception;

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
    
    override bar => sub { 'Baz::bar -> ' . super() };       
    override baz => sub { 'Baz::baz -> ' . super() }; 
}

my $baz = Baz->new();
isa_ok($baz, 'Baz');
isa_ok($baz, 'Bar');
isa_ok($baz, 'Foo');

is($baz->foo(), 'Foo::foo', '... got the right value from &foo');
is($baz->bar(), 'Baz::bar -> Bar::bar -> Foo::bar', '... got the right value from &bar');
is($baz->baz(), 'Baz::baz -> Foo::baz', '... got the right value from &baz');

my $bar = Bar->new();
isa_ok($bar, 'Bar');
isa_ok($bar, 'Foo');

is($bar->foo(), 'Foo::foo', '... got the right value from &foo');
is($bar->bar(), 'Bar::bar -> Foo::bar', '... got the right value from &bar');
is($bar->baz(), 'Foo::baz', '... got the right value from &baz');

my $foo = Foo->new();
isa_ok($foo, 'Foo');

is($foo->foo(), 'Foo::foo', '... got the right value from &foo');
is($foo->bar(), 'Foo::bar', '... got the right value from &bar');
is($foo->baz(), 'Foo::baz', '... got the right value from &baz');

# some error cases

{
    package Bling;
    use strict;
    use warnings;
    use Moose;
    
    sub bling { 'Bling::bling' }
    
    package Bling::Bling;
    use strict;
    use warnings;
    use Moose;
    
    extends 'Bling';
    
    sub bling { 'Bling::bling' }    
    
    ::dies_ok {
        override 'bling' => sub {};
    } '... cannot override a method which has a local equivalent';
    
}

