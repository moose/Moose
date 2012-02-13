#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

{
    package Foo;
    use Moose;
}

{
    is_deeply([Foo->meta->get_overload_list], []);
    is_deeply([Foo->meta->get_overloaded_operators], []);
}

my $plus;
my $plus_impl;
BEGIN { $plus_impl = sub { $plus = 1; $_[0] + $_[1] } }
{
    package Foo::Overloaded;
    use Moose;
    use overload '+' => $plus_impl;
}

{
    is_deeply([Foo::Overloaded->meta->get_overloaded_operators], ['+']);
    my @overloads = Foo::Overloaded->meta->get_overload_list;
    is(scalar(@overloads), 1);
    my $plus_meth = $overloads[0];
    isa_ok($plus_meth, 'Class::MOP::Method::Overload');
    is($plus_meth->operator, '+');
    is($plus_meth->name, '(+');
    is($plus_meth->body, $plus_impl);
    is($plus_meth->package_name, 'Foo::Overloaded');
    is($plus_meth->associated_metaclass, Foo::Overloaded->meta);
}

done_testing;
