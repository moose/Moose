#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

BEGIN {
    use_ok('Moose');           
}

{
    package Foo;
    use strict;
    use warnings;
    use Moose;
    
    sub foo { 'Foo::foo(' . (inner() || '') . ')' };
    sub bar { 'Foo::bar(' . (inner() || '') . ')' }
    
    package Bar;
    use strict;
    use warnings;
    use Moose;
    
    extends 'Foo';
    
    augment  'foo' => sub { 'Bar::foo' };
    override 'bar' => sub { 'Bar::bar -> ' . super() };    
    
    package Baz;
    use strict;
    use warnings;
    use Moose;
    
    extends 'Bar';
    
    override 'foo' => sub { 'Baz::foo -> ' . super() };
    augment  'bar' => sub { 'Baz::bar' };
}

my $baz = Baz->new();
isa_ok($baz, 'Baz');
isa_ok($baz, 'Bar');
isa_ok($baz, 'Foo');

=pod

Let em clarify what is happening here. Baz::foo is calling 
super(), which calls Bar::foo, which is an augmented sub 
that calls Foo::foo, then calls inner() which actually 
then calls Bar::foo. Confusing I know,.. but this is 
*exactly* what is it supposed to do :)

=cut

is($baz->foo, 
  'Baz::foo -> Foo::foo(Bar::foo)', 
  '... got the right value from mixed augment/override foo');

=pod

Allow me to clarify this one now ...

Since Baz::bar is an augment routine, it needs to find the 
correct inner() to be called by. In this case it is Foo::bar.
However, Bar::bar is inbetween us, so it should actually be
called first. Bar::bar is an overriden sub, and calls super()
which in turn then calls our Foo::bar, which calls inner(), 
which calls Baz::bar.

Confusing I know, but it is correct :)

=cut

is($baz->bar, 
    'Bar::bar -> Foo::bar(Baz::bar)', 
    '... got the right value from mixed augment/override bar');
