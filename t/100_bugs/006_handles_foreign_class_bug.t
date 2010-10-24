#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    package Foo;

    sub new {
        bless({}, 'Foo')
    }

    sub a { 'Foo::a' }
}

{
    package Bar;
    use Moose;

    ::ok ! ::exception {
        has 'baz' => (
            is      => 'ro',
            isa     => 'Foo',
            lazy    => 1,
            default => sub { Foo->new() },
            handles => qr/^a$/,
        );
    }, '... can create the attribute with delegations';

}

my $bar;
ok ! exception {
    $bar = Bar->new;
}, '... created the object ok';
isa_ok($bar, 'Bar');

is($bar->a, 'Foo::a', '... got the right delgated value');

my @w;
$SIG{__WARN__} = sub { push @w, "@_" };
{
    package Baz;
    use Moose;

    ::ok ! ::exception {
        has 'bar' => (
            is      => 'ro',
            isa     => 'Foo',
            lazy    => 1,
            default => sub { Foo->new() },
            handles => qr/.*/,
        );
    }, '... can create the attribute with delegations';

}

is(@w, 0, "no warnings");


my $baz;
ok ! exception {
    $baz = Baz->new;
}, '... created the object ok';
isa_ok($baz, 'Baz');

is($baz->a, 'Foo::a', '... got the right delgated value');





@w = ();

{
    package Blart;
    use Moose;

    ::ok ! ::exception {
        has 'bar' => (
            is      => 'ro',
            isa     => 'Foo',
            lazy    => 1,
            default => sub { Foo->new() },
            handles => [qw(a new)],
        );
    }, '... can create the attribute with delegations';

}

{
    local $TODO = "warning not yet implemented";

    is(@w, 1, "one warning");
    like($w[0], qr/not delegating.*new/i, "warned");
}



my $blart;
ok ! exception {
    $blart = Blart->new;
}, '... created the object ok';
isa_ok($blart, 'Blart');

is($blart->a, 'Foo::a', '... got the right delgated value');

done_testing;
