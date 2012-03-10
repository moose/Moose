#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
    package Foo;
    use Moose;
}

{
    my $meta = Foo->meta;

    ok(!$meta->is_overloaded);

    is_deeply([sort $meta->overload_operators],
              [sort map { split /\s+/ } values %overload::ops]);

    ok(!$meta->has_overloaded_operator('+'));
    ok(!$meta->has_overloaded_operator('-'));

    is_deeply([$meta->get_overload_list], []);

    is_deeply([$meta->get_all_overloaded_operators], []);

    is($meta->get_overloaded_operator('+'), undef);
    is($meta->get_overloaded_operator('-'), undef);
}

my $plus = 0;
my $plus_impl;
BEGIN { $plus_impl = sub { $plus = 1; "plus" } }
{
    package Foo::Overloaded;
    use Moose;
    use overload '+' => $plus_impl;
}

{
    my $meta = Foo::Overloaded->meta;

    ok($meta->is_overloaded);

    ok($meta->has_overloaded_operator('+'));
    ok(!$meta->has_overloaded_operator('-'));

    is_deeply([$meta->get_overload_list], ['+']);

    my @overloads = $meta->get_all_overloaded_operators;
    is(scalar(@overloads), 1);
    my $plus_meth = $overloads[0];
    isa_ok($plus_meth, 'Class::MOP::Method::Overload');
    is($plus_meth->operator, '+');
    is($plus_meth->name, '(+');
    is($plus_meth->body, $plus_impl);
    is($plus_meth->package_name, 'Foo::Overloaded');
    is($plus_meth->associated_metaclass, $meta);

    my $plus_meth2 = $meta->get_overloaded_operator('+');
    { local $TODO = "we don't cache these yet";
    is($plus_meth2, $plus_meth);
    }
    is($plus_meth2->operator, '+');
    is($plus_meth2->body, $plus_impl);
    is($meta->get_overloaded_operator('-'), undef);

    is($plus, 0);
    is(Foo::Overloaded->new + Foo::Overloaded->new, "plus");
    is($plus, 1);

    my $minus = 0;
    my $minus_impl = sub { $minus = 1; "minus" };

    like(exception { Foo::Overloaded->new - Foo::Overloaded->new },
         qr/Operation "-": no method found/);

    $meta->add_overloaded_operator('-' => $minus_impl);

    ok($meta->has_overloaded_operator('-'));

    is_deeply([sort $meta->get_overload_list], ['+', '-']);

    is(scalar($meta->get_all_overloaded_operators), 2);

    my $minus_meth = $meta->get_overloaded_operator('-');
    isa_ok($minus_meth, 'Class::MOP::Method::Overload');
    is($minus_meth->operator, '-');
    is($minus_meth->name, '(-');
    is($minus_meth->body, $minus_impl);
    is($minus_meth->package_name, 'Foo::Overloaded');
    is($minus_meth->associated_metaclass, $meta);

    is($minus, 0);
    is(Foo::Overloaded->new - Foo::Overloaded->new, "minus");
    is($minus, 1);
}

done_testing;
