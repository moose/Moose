#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;

ok(T3->isa('T1'), 'extablish is-a relationship at compile-time');

{
    package T1;
    use Moose -extends => [];
}

{
    package T2;
    use Moose -extends => [qw(T1)];
}

{
    package T3;
    use Moose -extends => 'T2';
}

lives_and {
    isa_ok(T1->new, 'T1');
};

lives_and {
    isa_ok(T2->new, 'T1');
    isa_ok(T2->new, 'T2');
};

lives_and {
    isa_ok(T3->new, 'T1');
    isa_ok(T3->new, 'T2');
    isa_ok(T3->new, 'T3');
};
