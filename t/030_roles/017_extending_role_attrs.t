#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 28;
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


{
    package Baz::Role;
    use Moose::Role;

    has 'baz' => (
        is      => 'rw',
        isa     => 'Value',
    );

    package Baz;
    use Moose;

    with 'Baz::Role';

    ::lives_ok {
        has '+baz' => (
            isa => 'Int | ClassName',
        )
    } "... narrowed the role's type constraint successfully";
}

my $baz = Baz->new(baz => 99);
isa_ok($baz, 'Baz');
is($baz->baz, 99, '... got the extended attribute');
$baz->baz('Foo');
is($baz->baz, 'Foo', "... can change the attribute's value to a ClassName");

throws_ok { $baz->baz("zonk") } qr/^Attribute \(baz\) does not pass the type constraint because: Validation failed for 'Int \| ClassName' failed with value zonk at /;
is_deeply($baz->baz, 'Foo', "... still has the old ClassName value");


{
    package Quux::Role;
    use Moose::Role;

    has 'quux' => (
        is      => 'rw',
        isa     => 'Str | Int | Ref',
    );

    package Quux;
    use Moose;
    use Moose::Util::TypeConstraints;

    with 'Quux::Role';

    subtype 'Positive'
        => as 'Int'
        => where { $_ > 0 };

    ::lives_ok {
        has '+quux' => (
            isa => 'Positive | ArrayRef',
        )
    } "... narrowed the role's type constraint successfully";
}

my $quux = Quux->new(quux => 99);
isa_ok($quux, 'Quux');
is($quux->quux, 99, '... got the extended attribute');
$quux->quux(100);
is($quux->quux, 100, "... can change the attribute's value to an Int");
$quux->quux(["hi"]);
is_deeply($quux->quux, ["hi"], "... can change the attribute's value to an ArrayRef");

throws_ok { $quux->quux("quux") } qr/^Attribute \(quux\) does not pass the type constraint because: Validation failed for 'Positive \| ArrayRef' failed with value quux at /;
is_deeply($quux->quux, ["hi"], "... still has the old ArrayRef value");

throws_ok { $quux->quux({a => 1}) } qr/^Attribute \(quux\) does not pass the type constraint because: Validation failed for 'Positive \| ArrayRef' failed with value HASH\(\w+\) at /;
is_deeply($quux->quux, ["hi"], "... still has the old ArrayRef value");


{
    package Err::Role;
    use Moose::Role;

    for (1..3) {
        has "err$_" => (
            isa => 'Str | Int',
        );
    }

    package Err;
    use Moose;

    with 'Err::Role';

    ::lives_ok {
        has '+err1' => (isa => 'Defined');
    } "can get less specific in the subclass";

    ::lives_ok {
        has '+err2' => (isa => 'Bool');
    } "or change the type completely";

    ::lives_ok {
        has '+err3' => (isa => 'Str | ArrayRef');
    } "or add new types to the union";
}

