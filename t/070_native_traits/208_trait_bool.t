#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

{
    package Room;
    use Moose;

    has 'is_lit' => (
        traits  => ['Bool'],
        is      => 'rw',
        isa     => 'Bool',
        default => 0,
        handles => {
            illuminate  => 'set',
            darken      => 'unset',
            flip_switch => 'toggle',
            is_dark     => 'not',
        },
        )
}

my $room = Room->new;
$room->illuminate;
ok( $room->is_lit, 'set is_lit to 1 using ->illuminate' );
ok( !$room->is_dark, 'check if is_dark does the right thing' );

$room->darken;
ok( !$room->is_lit, 'set is_lit to 0 using ->darken' );
ok( $room->is_dark, 'check if is_dark does the right thing' );

$room->flip_switch;
ok( $room->is_lit, 'toggle is_lit back to 1 using ->flip_switch' );
ok( !$room->is_dark, 'check if is_dark does the right thing' );

$room->flip_switch;
ok( !$room->is_lit, 'toggle is_lit back to 0 again using ->flip_switch' );
ok( $room->is_dark, 'check if is_dark does the right thing' );

done_testing;
