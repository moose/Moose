#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 52;
use Test::Exception;

BEGIN {
    use_ok('Moose');           
}

## Roles

{
    package Eq;
    use strict;
    use warnings;
    use Moose::Role;
    
    requires 'equal_to';
    
    sub not_equal_to { 
        my ($self, $other) = @_;
        !$self->equal_to($other);
    }
    
    package Ord;
    use strict;
    use warnings;
    use Moose::Role;
    
    with 'Eq';
    
    requires 'compare';
    
    sub equal_to {
        my ($self, $other) = @_;
        $self->compare($other) == 0;
    }    
    
    sub greater_than {
        my ($self, $other) = @_;
        $self->compare($other) == 1;
    }    
    
    sub less_than {
        my ($self, $other) = @_;
        $self->compare($other) == -1;
    }
    
    sub greater_than_or_equal_to {
        my ($self, $other) = @_;
        $self->greater_than($other) || $self->equal_to($other);
    }        

    sub less_than_or_equal_to {
        my ($self, $other) = @_;
        $self->less_than($other) || $self->equal_to($other);
    }    
}

## Classes

{
    package US::Currency;
    use strict;
    use warnings;
    use Moose;
    
    with 'Ord';
    
    has 'amount' => (is => 'rw', isa => 'Int', default => 0);
    
    sub compare {
        my ($self, $other) = @_;
        $self->amount <=> $other->amount;
    }
}

ok(US::Currency->does('Ord'), '... US::Currency does Ord');
ok(US::Currency->does('Eq'), '... US::Currency does Eq');

my $hundred = US::Currency->new(amount => 100.00);
isa_ok($hundred, 'US::Currency');

can_ok($hundred, 'amount');
is($hundred->amount, 100, '... got the right amount');

ok($hundred->does('Ord'), '... US::Currency does Ord');
ok($hundred->does('Eq'), '... US::Currency does Eq');

my $fifty = US::Currency->new(amount => 50.00);
isa_ok($fifty, 'US::Currency');

can_ok($fifty, 'amount');
is($fifty->amount, 50, '... got the right amount');

ok($hundred->greater_than($fifty),             '... 100 gt 50');
ok($hundred->greater_than_or_equal_to($fifty), '... 100 ge 50');
ok(!$hundred->less_than($fifty),               '... !100 lt 50');
ok(!$hundred->less_than_or_equal_to($fifty),   '... !100 le 50');
ok(!$hundred->equal_to($fifty),                '... !100 eq 50');
ok($hundred->not_equal_to($fifty),             '... 100 ne 50');

ok(!$fifty->greater_than($hundred),             '... !50 gt 100');
ok(!$fifty->greater_than_or_equal_to($hundred), '... !50 ge 100');
ok($fifty->less_than($hundred),                 '... 50 lt 100');
ok($fifty->less_than_or_equal_to($hundred),     '... 50 le 100');
ok(!$fifty->equal_to($hundred),                 '... !50 eq 100');
ok($fifty->not_equal_to($hundred),              '... 50 ne 100');

ok(!$fifty->greater_than($fifty),            '... !50 gt 50');
ok($fifty->greater_than_or_equal_to($fifty), '... !50 ge 50');
ok(!$fifty->less_than($fifty),               '... 50 lt 50');
ok($fifty->less_than_or_equal_to($fifty),    '... 50 le 50');
ok($fifty->equal_to($fifty),                 '... 50 eq 50');
ok(!$fifty->not_equal_to($fifty),            '... !50 ne 50');

## ... check some meta-stuff

# Eq

my $eq_meta = Eq->meta;
isa_ok($eq_meta, 'Moose::Meta::Role');

ok($eq_meta->has_method('not_equal_to'), '... Eq has_method not_equal_to');
ok($eq_meta->requires_method('equal_to'), '... Eq requires_method not_equal_to');

# Ord

my $ord_meta = Ord->meta;
isa_ok($ord_meta, 'Moose::Meta::Role');

ok($ord_meta->does_role('Eq'), '... Ord does Eq');

foreach my $method_name (qw(
                        equal_to not_equal_to
                        greater_than greater_than_or_equal_to
                        less_than less_than_or_equal_to                            
                        )) {
    ok($ord_meta->has_method($method_name), '... Ord has_method ' . $method_name);
}

ok($ord_meta->requires_method('compare'), '... Ord requires_method compare');

# US::Currency

my $currency_meta = US::Currency->meta;
isa_ok($currency_meta, 'Moose::Meta::Class');

ok($currency_meta->does_role('Ord'), '... US::Currency does Ord');
ok($currency_meta->does_role('Eq'), '... US::Currency does Eq');

foreach my $method_name (qw(
                        amount
                        equal_to not_equal_to
                        compare
                        greater_than greater_than_or_equal_to
                        less_than less_than_or_equal_to                            
                        )) {
    ok($currency_meta->has_method($method_name), '... US::Currency has_method ' . $method_name);
}

