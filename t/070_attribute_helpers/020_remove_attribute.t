#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;
use Test::Exception;

BEGIN {
    use_ok('Moose::AttributeHelpers');
}

{
    package MyHomePage;
    use Moose;

    has 'counter' => (
        metaclass => 'Counter',
        is        => 'ro',
        isa       => 'Int',
        default   => sub { 0 },
        provides  => {
            inc   => 'inc_counter',
            dec   => 'dec_counter',
            reset => 'reset_counter',
        }
    );
}

my $page = MyHomePage->new();
isa_ok($page, 'MyHomePage');

can_ok($page, $_) for qw[
    counter
    dec_counter
    inc_counter
    reset_counter
];

lives_ok {
    $page->meta->remove_attribute('counter')
} '... removed the counter attribute okay';

ok(!$page->meta->has_attribute('counter'), '... no longer has the attribute');

ok(!$page->can($_), "... our class no longer has the $_ method") for qw[
    counter
    dec_counter
    inc_counter
    reset_counter
];



