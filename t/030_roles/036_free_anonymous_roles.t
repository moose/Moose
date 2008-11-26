#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;
use Moose ();
use Scalar::Util 'weaken';

my $weak;
do {
    my $anon_class;

    do {
        my $role = Moose::Meta::Role->create_anon_role;
        weaken($weak = $role);

        $anon_class = Moose::Meta::Class->create_anon_class(
            roles => [ $role->name ],
        );
    };

    ok($weak, "we still have the role metaclass because the anonymous class that consumed it is still alive");

};

ok(!$weak, "the role metaclass is freed after its last reference (from a consuming anonymous class) is freed");

