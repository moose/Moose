#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;

{
    package NoOpTrait;
    use Moose::Role;
}

{
    package Parent;
    use Moose -traits => 'NoOpTrait';

    has attr => (
        is  => 'rw',
        isa => 'Str',
    );
}

{
    package Child;
    use base 'Parent';
}

is(Child->meta->name, 'Child', "correct metaclass name");

my $child = Child->new(attr => "ibute");
ok($child, "constructor works");

is($child->attr, "ibute", "getter inherited properly");

$child->attr("ition");
is($child->attr, "ition", "setter inherited properly");
