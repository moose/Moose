#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;

BEGIN {
    use_ok('Moose');
}

=pod

This basically just makes sure that using +name 
on role attributes works right.

=cut

{
    package Foo::Role;
    use Moose::Role;
    
    has 'bar' => (
        is      => 'rw',
        isa     => 'Int',   
        default => sub { 10 },
    );
    
    package Foo;
    use Moose;
    
    with 'Foo::Role';
    
    ::lives_ok {
        has '+bar' => (default => sub { 100 });
    } '... extended the attribute successfully';  
}

my $foo = Foo->new;
isa_ok($foo, 'Foo');

is($foo->bar, 100, '... got the extended attribute');

{
    package Bar::Role;
    use Moose::Role;

    has 'foo' => (
        is      => 'rw',
        isa     => 'Str | Int',
    );

    package Bar;
    use Moose;

    with 'Bar::Role';

    ::lives_ok {
        has '+foo' => (
            isa => 'Int',
        )
    } "... narrowed the role's type constraint successfully";
}


my $bar = Bar->new(foo => 42);
isa_ok($bar, 'Bar');
is($bar->foo, 42, '... got the extended attribute');
$bar->foo(100);
is($bar->foo, 100, "... can change the attribute's value to an Int");

throws_ok { $bar->foo("baz") } qr/^Attribute \(foo\) does not pass the type constraint because: Validation failed for 'Int' failed with value baz at /;
is($bar->foo, 100, "... still has the old Int value");

