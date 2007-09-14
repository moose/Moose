#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 9;
use Test::Exception;

BEGIN {
    use_ok('Moose');
}

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