use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Sub::Util 1.40 qw( set_subname );

my $quote = qr/['`"]/;

{
    package Foo;
    use Moose;
}

{
    my $meta = Foo->meta;

    subtest(
        'Foo class (not overloaded)',
        sub {
            ok( !$meta->is_overloaded, 'is not overloaded' );

            ok(
                !$meta->has_overloaded_operator('+'),
                'has no + overloading'
            );
            ok(
                !$meta->has_overloaded_operator('-'),
                'has no - overloading'
            );

            is_deeply(
                [ $meta->get_overload_list ], [],
                '->get_overload_list returns an empty list'
            );

            is_deeply(
                [ $meta->get_all_overloaded_operators ], [],
                '->get_all_overloaded_operators return an empty list'
            );

            is(
                $meta->get_overloaded_operator('+'), undef,
                'get_overloaded_operator(+) returns undef'
            );
            is(
                $meta->get_overloaded_operator('-'), undef,
                'get_overloaded_operator(-) returns undef'
            );
        }
    );
}

my $plus = 0;
my $plus_impl;

BEGIN {
    $plus_impl = sub { $plus = 1; 42 }
}
{
    package Foo::Overloaded;
    use Moose;
    use overload '+' => $plus_impl;
}

{
    my $meta = Foo::Overloaded->meta;

    subtest(
        'Foo::Overload class (overloaded with coderef)',
        sub {
            ok( $meta->is_overloaded, 'is overloaded' );

            ok(
                $meta->has_overloaded_operator('+'),
                'has + overloading'
            );
            ok(
                !$meta->has_overloaded_operator('-'),
                'has no - overloading'
            );

            is_deeply(
                [ $meta->get_overload_list ], ['+'],
                '->get_overload_list returns (+) '
            );

            my @overloads = $meta->get_all_overloaded_operators;
            is(
                scalar(@overloads), 1,
                '->get_all_overloaded_operators returns 1 operator'
            );
            my $plus_overload = $overloads[0];
            isa_ok(
                $plus_overload, 'Class::MOP::Overload',
                'overload object'
            );
            is( $plus_overload->operator, '+', 'operator for overload is +' );
            is(
                $plus_overload->coderef, $plus_impl,
                'coderef for overload matches sub we passed'
            );
            is(
                $plus_overload->coderef_package, 'main',
                'coderef package for overload is main'
            );
            is(
                $plus_overload->coderef_name, '__ANON__',
                'coderef name for overload is __ANON__'
            );
            ok(
                $plus_overload->is_anonymous,
                'overload is anonymous'
            );
            ok(
                !$plus_overload->has_method_name,
                'overload has no method name'
            );
            ok(
                !$plus_overload->has_method,
                'overload has no method'
            );
            is(
                $plus_overload->associated_metaclass, $meta,
                'overload is associated with expected metaclass'
            );

            my $plus_overload2 = $meta->get_overloaded_operator('+');
            is(
                $plus_overload2, $plus_overload,
                '->get_overloaded_operator(+) returns the same operator on each call'
            );

            is( $plus, 0, '+ overloading has not been called' );
            is(
                Foo::Overloaded->new + Foo::Overloaded->new, 42,
                '+ overloading returns 42'
            );
            is( $plus, 1, '+ overloading was called once' );

            ok(
                $plus_overload->_is_equal_to($plus_overload2),
                '_is_equal_to returns true for the exact same object'
            );

            my $plus_overload3 = Class::MOP::Overload->new(
                operator        => '+',
                coderef         => $plus_impl,
                coderef_package => 'main',
                coderef_name    => '__ANON__',
            );

            ok(
                $plus_overload->_is_equal_to($plus_overload3),
                '_is_equal_to returns true for object with the same properties'
            );

            my $minus = 0;
            my $minus_impl
                = set_subname( 'overload_minus', sub { $minus = 1; -42 } );

            like(
                exception { Foo::Overloaded->new - Foo::Overloaded->new },
                qr/Operation $quote-$quote: no .+ found/,
                'trying to call - on objects fails'
            );

            $meta->add_overloaded_operator( '-' => $minus_impl );

            ok(
                $meta->has_overloaded_operator('-'),
                'has - operator after call to ->add_overloaded_operator'
            );

            is_deeply(
                [ sort $meta->get_overload_list ], [ '+', '-' ],
                '->get_overload_list returns (+, -)'
            );

            is(
                scalar( $meta->get_all_overloaded_operators ), 2,
                '->get_all_overloaded_operators returns 2 operators'
            );

            my $minus_overload = $meta->get_overloaded_operator('-');
            isa_ok(
                $minus_overload, 'Class::MOP::Overload',
                'object for - overloading'
            );
            is(
                $minus_overload->operator, '-',
                'operator for overload is -'
            );
            is(
                $minus_overload->coderef, $minus_impl,
                'coderef for overload matches sub we passed'
            );
            is(
                $minus_overload->coderef_package, 'main',
                'coderef package for overload is main'
            );
            is(
                $minus_overload->coderef_name, 'overload_minus',
                'coderef name for overload is overload_minus'
            );
            ok(
                !$minus_overload->is_anonymous,
                'overload is not anonymous'
            );
            is(
                $minus_overload->associated_metaclass, $meta,
                'overload is associated with expected metaclass'
            );

            is( $minus, 0, '- overloading has not been called' );
            is(
                Foo::Overloaded->new - Foo::Overloaded->new, -42,
                '- overloading returns -42'
            );
            is( $minus, 1, '+- overloading was called once' );

            ok(
                !$plus_overload->_is_equal_to($minus_overload),
                '_is_equal_to returns false for objects with different properties'
            );

            $meta->remove_overloaded_operator('-');

            like(
                exception { Foo::Overloaded->new - Foo::Overloaded->new },
                qr/Operation $quote-$quote: no .+ found/,
                'trying to call - on objects fails after call to ->remove_overloaded_operator'
            );
        }
    );
}

my $times   = 0;
my $divided = 0;
{
    package Foo::OverloadWithMethod;
    use Moose;
    use overload '*' => 'times';

    sub times   { $times   = 1; 'times' }
    sub divided { $divided = 1; 'divided' }
}

{
    my $meta = Foo::OverloadWithMethod->meta;

    subtest(
        'Foo::OverloadWithMethod (overloaded via method)',
        sub {
            ok(
                $meta->is_overloaded,
                'is overloaded'
            );

            ok(
                $meta->has_overloaded_operator('*'),
                'overloads *'
            );
            ok(
                !$meta->has_overloaded_operator('/'),
                'does not overload /'
            );

            is_deeply(
                [ $meta->get_overload_list ], ['*'],
                '->get_overload_list returns (*)'
            );

            my @overloads = $meta->get_all_overloaded_operators;
            is(
                scalar(@overloads), 1,
                '->get_all_overloaded_operators returns 1 item'
            );
            my $times_overload = $overloads[0];
            isa_ok(
                $times_overload, 'Class::MOP::Overload',
                'overload object'
            );
            is(
                $times_overload->operator, '*',
                'operator for overload is +'
            );
            ok(
                $times_overload->has_method_name,
                'overload has a method name'
            );
            is(
                $times_overload->method_name, 'times',
                q{method name is 'times'}
            );
            ok(
                !$times_overload->has_coderef,
                'overload does not have a coderef'
            );
            ok(
                !$times_overload->has_coderef_package,
                'overload does not have a coderef package'
            );
            ok(
                !$times_overload->has_coderef_name,
                'overload does not have a coderef name'
            );
            ok(
                !$times_overload->is_anonymous,
                'overload is not anonymous'
            );
            ok(
                $times_overload->has_method,
                'overload has a method'
            );
            is(
                $times_overload->method, $meta->get_method('times'),
                '->method returns method object for times method'
            );
            is(
                $times_overload->associated_metaclass, $meta,
                'overload is associated with expected metaclass'
            );

            is( $times, 0, '* overloading has not been called' );
            is(
                Foo::OverloadWithMethod->new * Foo::OverloadWithMethod->new,
                'times',
                q{* overloading returns 'times'}
            );
            is( $times, 1, '* overloading was called once' );

            my $times_overload2 = $meta->get_overloaded_operator('*');

            ok(
                $times_overload->_is_equal_to($times_overload2),
                '_is_equal_to returns true for the exact same object'
            );

            my $times_overload3 = Class::MOP::Overload->new(
                operator    => '*',
                method_name => 'times',
            );

            ok(
                $times_overload->_is_equal_to($times_overload3),
                '_is_equal_to returns true for object with the same properties'
            );

            like(
                exception {
                    Foo::OverloadWithMethod->new
                        / Foo::OverloadWithMethod->new
                },
                qr{Operation $quote/$quote: no .+ found},
                'trying to call / on objects fails'
            );

            $meta->add_overloaded_operator( '/' => 'divided' );

            ok(
                $meta->has_overloaded_operator('/'),
                'has / operator after call to ->add_overloaded_operator'
            );

            is_deeply(
                [ sort $meta->get_overload_list ], [ '*', '/' ],
                '->get_overload_list returns (*, /)'
            );

            is(
                scalar( $meta->get_all_overloaded_operators ), 2,
                '->get_all_overloaded_operators returns 2 operators'
            );

            my $divided_overload = $meta->get_overloaded_operator('/');
            isa_ok(
                $divided_overload, 'Class::MOP::Overload',
                'overload object'
            );
            is(
                $divided_overload->operator, '/',
                'operator for overload is /'
            );
            is(
                $divided_overload->method_name, 'divided',
                q{method name is 'divided'}
            );
            is(
                $divided_overload->method, $meta->get_method('divided'),
                '->method returns method object for divided method'
            );
            is(
                $divided_overload->associated_metaclass, $meta,
                'overload is associated with expected metaclass'
            );

            $meta->remove_overloaded_operator('/');

            like(
                exception {
                    Foo::OverloadWithMethod->new
                        / Foo::OverloadWithMethod->new
                },
                qr{Operation $quote/$quote: no .+ found},
                'trying to call / on objects fails after call to ->remove_overloaded_operator'
            );
        }
    );
}

{
    package Foo::UnimplementedOverload;
    use Moose;
    use overload '+' => 'plus';
}

{
    my $meta = Foo::UnimplementedOverload->meta;

    subtest(
        'Foo::UnimplementedOverload (overloaded via method that does not exist)',
        sub {
            ok(
                $meta->is_overloaded,
                'is overloaded'
            );

            ok(
                $meta->has_overloaded_operator('+'),
                'overloads +'
            );

            my $plus_overload = $meta->get_overloaded_operator('+');
            isa_ok(
                $plus_overload, 'Class::MOP::Overload',
                'overload object'
            );
            is(
                $plus_overload->operator, '+',
                'operator for overload is +'
            );
            ok(
                $plus_overload->has_method_name,
                'overload has a method name'
            );
            is(
                $plus_overload->method_name, 'plus',
                q{method name is 'plus'}
            );
            ok(
                !$plus_overload->has_coderef,
                'overload does not have a coderef'
            );
            ok(
                !$plus_overload->has_coderef_package,
                'overload does not have a coderef package'
            );
            ok(
                !$plus_overload->has_coderef_name,
                'overload does not have a coderef name'
            );
            ok(
                !$plus_overload->is_anonymous,
                'overload is not anonymous'
            );
            ok(
                !$plus_overload->has_method,
                'overload has no method object'
            );
            is(
                $plus_overload->associated_metaclass, $meta,
                'overload is associated with expected metaclass'
            );
        }
    );
}

done_testing;
