#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;


{
    package Customer;
    use Moose;

    package Firm;
    use Moose;
    use Moose::Util::TypeConstraints;

    ::lives_ok {
        has 'customers' => (
            is         => 'ro',
            isa        => subtype('ArrayRef' => where {
                            (blessed($_) && $_->isa('Customer') || return) for @$_; 1 }),
            auto_deref => 1,
        );
    } '... successfully created attr';
}

{
    my $customer = Customer->new;
    isa_ok($customer, 'Customer');

    my $firm = Firm->new(customers => [ $customer ]);
    isa_ok($firm, 'Firm');

    can_ok($firm, 'customers');

    is_deeply(
        [ $firm->customers ],
        [ $customer ],
        '... got the right dereferenced value'
    );
}

{
    my $firm = Firm->new();
    isa_ok($firm, 'Firm');

    can_ok($firm, 'customers');

    is_deeply(
        [ $firm->customers ],
        [],
        '... got the right dereferenced value'
    );
}

{
    package AutoDeref;
    use Moose;

    has 'bar' => (
        is         => 'rw',
        isa        => 'ArrayRef[Int]',
        auto_deref => 1,
    );
}

{
    my $autoderef = AutoDeref->new;

    dies_ok {
        $autoderef->bar(1, 2, 3);
    } '... its auto-de-ref-ing, not auto-en-ref-ing';

    lives_ok  {
        $autoderef->bar([ 1, 2, 3 ])
    } '... set the results of bar correctly';

    is_deeply [ $autoderef->bar ], [ 1, 2, 3 ], '... auto-dereffed correctly';
}

done_testing;
