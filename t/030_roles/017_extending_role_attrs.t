#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 29;
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
        isa     => 'Str | Int | ArrayRef',
    );

    package Baz;
    use Moose;

    with 'Baz::Role';

    ::lives_ok {
        has '+baz' => (
            isa => 'Int | ArrayRef',
        )
    } "... narrowed the role's type constraint successfully";
}


my $baz = Baz->new(baz => 99);
isa_ok($baz, 'Baz');
is($baz->baz, 99, '... got the extended attribute');
$baz->baz(100);
is($baz->baz, 100, "... can change the attribute's value to an Int");
$baz->baz(["hi"]);
is_deeply($baz->baz, ["hi"], "... can change the attribute's value to an ArrayRef");

throws_ok { $baz->baz("quux") } qr/^Attribute \(baz\) does not pass the type constraint because: Validation failed for 'Int \| ArrayRef' failed with value quux at /;
is_deeply($baz->baz, ["hi"], "... still has the old ArrayRef value");

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

    has "err" => (
        isa => 'Str | Int',
    );

    package Err;
    use Moose;

    with 'Err::Role';

    my $error = qr/New type constraint setting must be a subtype of inherited one, or included in the inherited constraint/;

    ::throws_ok {
        has '+err' => (isa => 'Defined');
    } $error, "must get more specific, not less specific";

    ::throws_ok {
        has '+err' => (isa => 'Bool');
    } $error, "the type has to be a part of the union";

    ::throws_ok {
        has '+err' => (isa => 'Str | ArrayRef');
    } $error, "can't add new types to the union";
}

