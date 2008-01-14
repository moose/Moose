#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;

BEGIN {
    use_ok('Moose');
}

{
    package Foo;
    use Moose::Role;
    
    sub foo   { 'Foo::foo'   }
    sub bar   { 'Foo::bar'   }
    sub baz   { 'Foo::baz'   }
    sub gorch { 'Foo::gorch' }            
    
    package Bar;
    use Moose::Role;

    sub foo   { 'Bar::foo'   }
    sub bar   { 'Bar::bar'   }
    sub baz   { 'Bar::baz'   }
    sub gorch { 'Bar::gorch' }    

    package Baz;
    use Moose::Role;
    
    sub foo   { 'Baz::foo'   }
    sub bar   { 'Baz::bar'   }
    sub baz   { 'Baz::baz'   }
    sub gorch { 'Baz::gorch' }            
    
    package Gorch;
    use Moose::Role;
    
    sub foo   { 'Gorch::foo'   }
    sub bar   { 'Gorch::bar'   }
    sub baz   { 'Gorch::baz'   }
    sub gorch { 'Gorch::gorch' }        
}

{
    package My::Class;
    use Moose;
    
    ::lives_ok {
        with 'Foo'   => { excludes => [qw/bar baz gorch/], alias => { gorch => 'foo_gorch' } },
             'Bar'   => { excludes => [qw/foo baz gorch/] },
             'Baz'   => { excludes => [qw/foo bar gorch/], alias => { foo => 'baz_foo', bar => 'baz_bar' } },
             'Gorch' => { excludes => [qw/foo bar baz/] };
    } '... everything works out all right';
}

my $c = My::Class->new;
isa_ok($c, 'My::Class');

is($c->foo, 'Foo::foo', '... got the right method');
is($c->bar, 'Bar::bar', '... got the right method');
is($c->baz, 'Baz::baz', '... got the right method');
is($c->gorch, 'Gorch::gorch', '... got the right method');

is($c->foo_gorch, 'Foo::gorch', '... got the right method');
is($c->baz_foo, 'Baz::foo', '... got the right method');
is($c->baz_bar, 'Baz::bar', '... got the right method');





