#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;

BEGIN {
    use_ok('Moose');           
}

{
    # NOTE:
    # this tests that repeated role 
    # composition will not cause 
    # a conflict between two methods
    # which are actually the same anyway
    
    {
        package RootA;
        use Moose::Role;

        sub foo { "RootA::foo" }

        package SubAA;
        use Moose::Role;

        with "RootA";

        sub bar { "SubAA::bar" }

        package SubAB;
        use Moose;

        ::lives_ok { 
            with "SubAA", "RootA"; 
        } '... role was composed as expected';
    }

    ok( SubAB->does("SubAA"), "does SubAA");
    ok( SubAB->does("RootA"), "does RootA");

    isa_ok( my $i = SubAB->new, "SubAB" );

    can_ok( $i, "bar" );
    is( $i->bar, "SubAA::bar", "... got thr right bar rv" );

    can_ok( $i, "foo" );
    my $foo_rv;
    lives_ok { 
        $foo_rv = $i->foo; 
    } '... called foo successfully';
    is($foo_rv, "RootA::foo", "... got the right foo rv");
}

