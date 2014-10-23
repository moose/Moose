use strict;
use warnings;
use Test::More;
use Test::Fatal;

my $quote = qr/['`"]/;

{
    package Foo;
    use Moose;
}

{
    my $meta = Foo->meta;

    ok(!$meta->is_overloaded);

    ok(!$meta->has_overloaded_operator('+'));
    ok(!$meta->has_overloaded_operator('-'));

    is_deeply([$meta->overloaded_operators], []);

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

    is_deeply([$meta->overloaded_operators], ['+']);

    my @overloads = $meta->get_all_overloaded_operators;
    is(scalar(@overloads), 1);
    my $plus_overload = $overloads[0];
    isa_ok($plus_overload, 'Class::MOP::Overload');
    is($plus_overload->operator, '+');
    is($plus_overload->coderef, $plus_impl);
    is($plus_overload->coderef_package, 'main');
    is($plus_overload->coderef_name, '__ANON__');
    is($plus_overload->associated_metaclass, $meta);

    my $plus_overload2 = $meta->get_overloaded_operator('+');
    { local $TODO = "we don't cache these yet";
    is($plus_overload2, $plus_overload);
    }
    is($plus_overload2->operator, '+');
    is($plus_overload2->coderef, $plus_impl);
    is($meta->get_overloaded_operator('-'), undef);

    is($plus, 0);
    is(Foo::Overloaded->new + Foo::Overloaded->new, "plus");
    is($plus, 1);

    my $minus = 0;
    my $minus_impl = sub { $minus = 1; "minus" };

    like(exception { Foo::Overloaded->new - Foo::Overloaded->new },
         qr/Operation $quote-$quote: no .+ found/);

    $meta->add_overloaded_operator('-' => $minus_impl);

    ok($meta->has_overloaded_operator('-'));

    is_deeply([sort $meta->overloaded_operators], ['+', '-']);

    is(scalar($meta->get_all_overloaded_operators), 2);

    my $minus_overload = $meta->get_overloaded_operator('-');
    isa_ok($minus_overload, 'Class::MOP::Overload');
    is($minus_overload->operator, '-');
    is($minus_overload->coderef, $minus_impl);
    is($minus_overload->coderef_package, 'main');
    is($minus_overload->associated_metaclass, $meta);

    is($minus, 0);
    is(Foo::Overloaded->new - Foo::Overloaded->new, "minus");
    is($minus, 1);

    $meta->remove_overloaded_operator('-');

    like(exception { Foo::Overloaded->new - Foo::Overloaded->new },
         qr/Operation $quote-$quote: no .+ found/);
}

my $times = 0;
my $divided = 0;
{
    package Foo::OverloadWithMethod;
    use Moose;
    use overload '*' => 'times';

    sub times   { $times = 1;   "times" }
    sub divided { $divided = 1; "divided" }
}

{
    my $meta = Foo::OverloadWithMethod->meta;

    ok($meta->is_overloaded);

    ok($meta->has_overloaded_operator('*'));
    ok(!$meta->has_overloaded_operator('/'));

    is_deeply([$meta->overloaded_operators], ['*']);

    my @overloads = $meta->get_all_overloaded_operators;
    is(scalar(@overloads), 1);
    my $times_overload = $overloads[0];
    isa_ok($times_overload, 'Class::MOP::Overload');
    is($times_overload->operator, '*');
    is($times_overload->method_name, 'times');
    is($times_overload->method, $meta->get_method('times'));
    is($times_overload->associated_metaclass, $meta);

    my $times_overload2 = $meta->get_overloaded_operator('*');
    { local $TODO = "we don't cache these yet";
    is($times_overload2, $times_overload);
    }
    is($times_overload2->operator, '*');
    is($times_overload->method_name, 'times');
    is($times_overload->method, $meta->get_method('times'));
    is($meta->get_overloaded_operator('/'), undef);

    is($times, 0);
    is(Foo::OverloadWithMethod->new * Foo::OverloadWithMethod->new, "times");
    is($times, 1);

    like(exception { Foo::OverloadWithMethod->new / Foo::OverloadWithMethod->new },
         qr{Operation $quote/$quote: no .+ found});

    $meta->add_overloaded_operator('/' => 'divided');

    ok($meta->has_overloaded_operator('/'));

    is_deeply([sort $meta->overloaded_operators], ['*', '/']);

    is(scalar($meta->get_all_overloaded_operators), 2);

    my $divided_overload = $meta->get_overloaded_operator('/');
    isa_ok($divided_overload, 'Class::MOP::Overload');
    is($divided_overload->operator, '/');
    is($divided_overload->method_name, 'divided');
    is($divided_overload->method, $meta->get_method('divided'));
    is($divided_overload->associated_metaclass, $meta);

    is($divided, 0);
    is(Foo::OverloadWithMethod->new / Foo::OverloadWithMethod->new, "divided");
    is($divided, 1);

    $meta->remove_overloaded_operator('/');

    like(exception { Foo::OverloadWithMethod->new / Foo::OverloadWithMethod->new },
         qr{Operation $quote/$quote: no .+ found});
}

done_testing;
