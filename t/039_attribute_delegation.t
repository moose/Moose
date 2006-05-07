#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 46;
use Test::Exception;

BEGIN {  
    use_ok('Moose');               
}

# the canonical form of of the 'handles'
# option is the hash ref mapping a 
# method name to the delegated method name

{
    package Foo;
    use strict;
    use warnings;
    use Moose;

    has 'bar' => (is => 'rw', default => 10);    

    package Bar;
    use strict;
    use warnings;
    use Moose; 
    
    has 'foo' => (
        is      => 'rw',
        default => sub { Foo->new },
        handles => { 'foo_bar' => 'bar' }
    );
}

my $bar = Bar->new;
isa_ok($bar, 'Bar');

ok($bar->foo, '... we have something in bar->foo');
isa_ok($bar->foo, 'Foo');

is($bar->foo->bar, 10, '... bar->foo->bar returned the right default');

can_ok($bar, 'foo_bar');
is($bar->foo_bar, 10, '... bar->foo_bar delegated correctly');

my $foo = Foo->new(bar => 25);
isa_ok($foo, 'Foo');

is($foo->bar, 25, '... got the right foo->bar');

lives_ok {
    $bar->foo($foo);
} '... assigned the new Foo to Bar->foo';

is($bar->foo, $foo, '... assigned bar->foo with the new Foo');

is($bar->foo->bar, 25, '... bar->foo->bar returned the right result');
is($bar->foo_bar, 25, '... and bar->foo_bar delegated correctly again');

# we also support an array based format
# which assumes that the name is the same 
# on either end

{
    package Engine;
    use strict;
    use warnings;
    use Moose;

    sub go   { 'Engine::go'   }
    sub stop { 'Engine::stop' }    

    package Car;
    use strict;
    use warnings;
    use Moose; 
    
    has 'engine' => (
        is      => 'rw',
        default => sub { Engine->new },
        handles => [ 'go', 'stop' ]
    );
}

my $car = Car->new;
isa_ok($car, 'Car');

isa_ok($car->engine, 'Engine');
can_ok($car->engine, 'go');
can_ok($car->engine, 'stop');

is($car->engine->go, 'Engine::go', '... got the right value from ->engine->go');
is($car->engine->stop, 'Engine::stop', '... got the right value from ->engine->stop');

can_ok($car, 'go');
can_ok($car, 'stop');

is($car->go, 'Engine::go', '... got the right value from ->go');
is($car->stop, 'Engine::stop', '... got the right value from ->stop');

# and we support regexp delegation

{
    package Baz;
    use strict;
    use warnings;
    use Moose;

    sub foo { 'Baz::foo' }
    sub bar { 'Baz::bar' }       
    sub boo { 'Baz::boo' }            

    package Baz::Proxy1;
    use strict;
    use warnings;
    use Moose; 
    
    has 'baz' => (
        is      => 'ro',
        isa     => 'Baz',
        default => sub { Baz->new },
        handles => qr/.*/
    );
    
    package Baz::Proxy2;
    use strict;
    use warnings;
    use Moose; 
    
    has 'baz' => (
        is      => 'ro',
        isa     => 'Baz',
        default => sub { Baz->new },
        handles => qr/.oo/
    );    
    
    package Baz::Proxy3;
    use strict;
    use warnings;
    use Moose; 
    
    has 'baz' => (
        is      => 'ro',
        isa     => 'Baz',
        default => sub { Baz->new },
        handles => qr/b.*/
    );    
}

{
    my $baz_proxy = Baz::Proxy1->new;
    isa_ok($baz_proxy, 'Baz::Proxy1');

    can_ok($baz_proxy, 'baz');
    isa_ok($baz_proxy->baz, 'Baz');

    can_ok($baz_proxy, 'foo');
    can_ok($baz_proxy, 'bar');
    can_ok($baz_proxy, 'boo');
    
    is($baz_proxy->foo, 'Baz::foo', '... got the right proxied return value');
    is($baz_proxy->bar, 'Baz::bar', '... got the right proxied return value');
    is($baz_proxy->boo, 'Baz::boo', '... got the right proxied return value');    
}
{
    my $baz_proxy = Baz::Proxy2->new;
    isa_ok($baz_proxy, 'Baz::Proxy2');

    can_ok($baz_proxy, 'baz');
    isa_ok($baz_proxy->baz, 'Baz');

    can_ok($baz_proxy, 'foo');
    can_ok($baz_proxy, 'boo');
    
    is($baz_proxy->foo, 'Baz::foo', '... got the right proxied return value');
    is($baz_proxy->boo, 'Baz::boo', '... got the right proxied return value');    
}
{
    my $baz_proxy = Baz::Proxy3->new;
    isa_ok($baz_proxy, 'Baz::Proxy3');

    can_ok($baz_proxy, 'baz');
    isa_ok($baz_proxy->baz, 'Baz');

    can_ok($baz_proxy, 'bar');
    can_ok($baz_proxy, 'boo');
    
    is($baz_proxy->bar, 'Baz::bar', '... got the right proxied return value');
    is($baz_proxy->boo, 'Baz::boo', '... got the right proxied return value');    
}


