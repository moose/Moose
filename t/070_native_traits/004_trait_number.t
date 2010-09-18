#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Moose;

{
    package Real;
    use Moose;

    has 'integer' => (
        traits  => ['Number'],
        is      => 'ro',
        isa     => 'Int',
        default => 5,
        handles => {
            set         => 'set',
            add         => 'add',
            sub         => 'sub',
            mul         => 'mul',
            div         => 'div',
            mod         => 'mod',
            abs         => 'abs',
            inc         => [ add => 1 ],
            dec         => [ sub => 1 ],
            odd         => [ mod => 2 ],
            cut_in_half => [ div => 2 ],

        },
    );
}

my $real = Real->new;
isa_ok( $real, 'Real' );

can_ok( $real, $_ ) for qw[
    set add sub mul div mod abs inc dec odd cut_in_half
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

$real->set(12);

$real->inc;

is $real->integer, 13, 'inc 12';

$real->dec;

is $real->integer, 12, 'dec 13';

## test the meta

my $attr = $real->meta->get_attribute('integer');
does_ok( $attr, 'Moose::Meta::Attribute::Native::Trait::Number' );

is_deeply(
    $attr->handles,
    {
        set         => 'set',
        add         => 'add',
        sub         => 'sub',
        mul         => 'mul',
        div         => 'div',
        mod         => 'mod',
        abs         => 'abs',
        inc         => [ add => 1 ],
        dec         => [ sub => 1 ],
        odd         => [ mod => 2 ],
        cut_in_half => [ div => 2 ],
    },
    '... got the right handles mapping'
);

done_testing;
