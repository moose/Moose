#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

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

    ::lives_ok {
        has 'baz' => (
            is      => 'ro',
            isa     => 'Foo',
            lazy    => 1,
            default => sub { Foo->new() },
            handles => qr/^a$/,
        );
    } '... can create the attribute with delegations';

}

my $bar;
lives_ok {
    $bar = Bar->new;
} '... created the object ok';
isa_ok($bar, 'Bar');

is($bar->a, 'Foo::a', '... got the right delgated value');

my @w;
$SIG{__WARN__} = sub { push @w, "@_" };
{
    package Baz;
    use Moose;

    ::lives_ok {
        has 'bar' => (
            is      => 'ro',
            isa     => 'Foo',
            lazy    => 1,
            default => sub { Foo->new() },
            handles => qr/.*/,
        );
    } '... can create the attribute with delegations';

}

is(@w, 0, "no warnings");


my $baz;
lives_ok {
    $baz = Baz->new;
} '... created the object ok';
isa_ok($baz, 'Baz');

is($baz->a, 'Foo::a', '... got the right delgated value');





@w = ();

{
    package Blart;
    use Moose;

    ::lives_ok {
        has 'bar' => (
            is      => 'ro',
            isa     => 'Foo',
            lazy    => 1,
            default => sub { Foo->new() },
            handles => [qw(a new)],
        );
    } '... can create the attribute with delegations';

}

{
    local $TODO = "warning not yet implemented";

    is(@w, 1, "one warning");
    like($w[0], qr/not delegating.*new/i, "warned");
}



my $blart;
lives_ok {
    $blart = Blart->new;
} '... created the object ok';
isa_ok($blart, 'Blart');

is($blart->a, 'Foo::a', '... got the right delgated value');

done_testing;
