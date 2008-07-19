#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 7;

# this test script ensures that my idiom of:
# role: sub BUILD, after BUILD
# continues to work to run code after object initialization, whether the class
# has a BUILD method or not

BEGIN {
    use_ok('Moose::Role');
}

my @CALLS;

do {
    package TestRole;
    use Moose::Role;

    sub BUILD           { push @CALLS, 'TestRole::BUILD' }
    before BUILD => sub { push @CALLS, 'TestRole::BUILD:before' };
    after  BUILD => sub { push @CALLS, 'TestRole::BUILD:after' };
};

do {
    package ClassWithBUILD;
    use Moose;
    with 'TestRole';

    sub BUILD { push @CALLS, 'ClassWithBUILD::BUILD' }
};

do {
    package ClassWithoutBUILD;
    use Moose;
    with 'TestRole';
};

is_deeply([splice @CALLS], [], "no calls to BUILD yet");

ClassWithBUILD->new;

is_deeply([splice @CALLS], [
    'TestRole::BUILD:before',
    'ClassWithBUILD::BUILD',
    'TestRole::BUILD:after',
]);

ClassWithoutBUILD->new;

is_deeply([splice @CALLS], [
    'TestRole::BUILD:before',
    'TestRole::BUILD',
    'TestRole::BUILD:after',
]);

ClassWithBUILD->meta->make_immutable;
ClassWithoutBUILD->meta->make_immutable;

is_deeply([splice @CALLS], [], "no calls to BUILD yet");

ClassWithBUILD->new;

is_deeply([splice @CALLS], [
    'TestRole::BUILD:before',
    'ClassWithBUILD::BUILD',
    'TestRole::BUILD:after',
]);

ClassWithoutBUILD->new;

is_deeply([splice @CALLS], [
    'TestRole::BUILD:before',
    'TestRole::BUILD',
    'TestRole::BUILD:after',
]);

