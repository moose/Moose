#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 20;
use Test::Moose;

BEGIN {
    use_ok('Moose::AttributeHelpers');
}

{
    package Real;
    use Moose;

    has 'integer' => (
        traits    => [qw/Number/],
        is        => 'ro',
        isa       => 'Int',
        default   => sub { 5 },
        provides  => {
            set => 'set',
            add => 'add',
            sub => 'sub',
            mul => 'mul',
            div => 'div',
            mod => 'mod',
            abs => 'abs',
        }
    );
}

my $real = Real->new;
isa_ok($real, 'Real');

can_ok($real, $_) for qw[
    set add sub mul div mod abs
];

is $real->integer, 5, 'Default to five';

$real->add(10);

is $real->integer, 15, 'Add ten for fithteen';

$real->sub(3);

is $real->integer, 12, 'Subtract three for 12';

$real->set(10);

is $real->integer, 10, 'Set to ten';

$real->div(2);

is $real->integer, 5, 'divide by 2';

$real->mul(2);

is $real->integer, 10, 'multiplied by 2';

$real->mod(2);

is $real->integer, 0, 'Mod by 2';

$real->set(7);

$real->mod(5);

is $real->integer, 2, 'Mod by 5';

$real->set(-1);

$real->abs;

is $real->integer, 1, 'abs 1';

## test the meta

my $attr = $real->meta->get_attribute('integer');
does_ok($attr, 'Moose::AttributeHelpers::Trait::Number');

is_deeply($attr->provides, {
    set => 'set',
    add => 'add',
    sub => 'sub',
    mul => 'mul',
    div => 'div',
    mod => 'mod',
    abs => 'abs',
}, '... got the right provides mapping');

