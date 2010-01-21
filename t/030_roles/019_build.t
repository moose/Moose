#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Moose;
BEGIN {
    eval "use Test::Output;";
    plan skip_all => "Test::Output is required for this test" if $@;
}

# this test script ensures that my idiom of:
# role: sub BUILD, after BUILD
# continues to work to run code after object initialization, whether the class
# has a BUILD method or not
# note: as of moose 0.95, this idiom is no longer necessary ('after BUILD' on
# its own is sufficient)  -doy

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

    ::stderr_is {
        with 'TestRole';
    } '';

    sub BUILD { push @CALLS, 'ClassWithBUILD::BUILD' }
};

do {
    package ExplicitClassWithBUILD;
    use Moose;

    ::stderr_is {
        with 'TestRole' => { excludes => 'BUILD' };
    } '';

    sub BUILD { push @CALLS, 'ExplicitClassWithBUILD::BUILD' }
};

do {
    package ClassWithoutBUILD;
    use Moose;
    with 'TestRole';
};

do {
    package TestRoleWithoutBUILD;
    use Moose::Role;

    before BUILD => sub { push @CALLS, 'TestRoleWithoutBUILD::BUILD:before' };
    after  BUILD => sub { push @CALLS, 'TestRoleWithoutBUILD::BUILD:after' };
};

do {
    package AnotherClassWithBUILD;
    use Moose;

    ::stderr_is {
        with 'TestRoleWithoutBUILD';
    } '';

    sub BUILD { push @CALLS, 'AnotherClassWithBUILD::BUILD' }
};

do {
    package AnotherClassWithoutBUILD;
    use Moose;

    ::stderr_is {
        with 'TestRoleWithoutBUILD';
    } '';
};

with_immutable {
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

    AnotherClassWithBUILD->new;

    is_deeply([splice @CALLS], [
        'TestRoleWithoutBUILD::BUILD:before',
        'AnotherClassWithBUILD::BUILD',
        'TestRoleWithoutBUILD::BUILD:after',
    ]);

    AnotherClassWithoutBUILD->new;

    is_deeply([splice @CALLS], [
        'TestRoleWithoutBUILD::BUILD:before',
        'TestRoleWithoutBUILD::BUILD:after',
    ]);
} qw(ClassWithBUILD        ClassWithoutBUILD
     AnotherClassWithBUILD AnotherClassWithoutBUILD);

done_testing;
