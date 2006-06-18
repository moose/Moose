#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 65;

{
    {
        package RootA;
        use Moose::Role;

        sub foo {
            "foo rv";
        }

        package SubAA;
        use Moose::Role;

        with "RootA";

        sub bar {
            "bar rv";
        }

        package SubAB;
        use Moose;

        eval { with "SubAA" };


    }

    ok( SubAB->does("SubAA"), "does SubAA");
    ok( SubAB->does("RootA"), "does RootA");

    isa_ok( my $i = SubAB->new, "SubAB" );

    can_ok( $i, "bar" );
    is( $i->bar, "bar rv", "bar rv" );

    can_ok( $i, "foo" );
    is( eval { $i->foo }, "foo rv", "foo rv" );
}

{
    {
        package RootB;
        use Moose::Role;

        sub foo {
            "foo rv";
        }

        package SubBA;
        use Moose::Role;

        with "RootB";

        has counter => (
            isa => "Num",
            is  => "rw",
            default => 0,
        );

        after foo => sub {
            $_[0]->counter( $_[0]->counter + 1 );
        };

        package SubBB;
        use Moose;

        eval { with "SubBA" };
    }

    ok( SubBB->does("SubBA"), "BB does SubBA" );
    ok( SubBB->does("RootB"), "BB does RootB" );

    isa_ok( my $i = SubBB->new, "SubBB" );

    can_ok( $i, "foo" );
    is( eval { $i->foo }, "foo rv", "foo rv" );

    is( $i->counter, 1, "after hook called" );
}

{
    {
        package RootC;
        use Moose::Role;

        sub foo {
            "foo rv";
        }

        package SubCA;
        use Moose::Role;

        with "RootC";

        override foo => sub {
            "overridden";
        };

        package SubCB;
        use Moose;

        eval { with "SubCA" };

        package SubCC;
        use Moose;

        undef $@;
        eval {
            with qw/
                SubCA
                RootC
            /;
        };

        ::ok( $@, "can't compose role with conflict and diamond hierarchy" );

        package SubCD;
        use Moose::Role;

        with "RootC";

        package SubCE;
        use Moose;

        undef $@;
        eval { with qw/SubCD RootC/ };
        ::ok( !$@, "can compose if appearantly conflicting method is actually the same one" );
    }

    ok( SubCB->does("SubCA"), "CB does SubCA" );
    ok( SubCB->does("RootC"), "CB does RootC" );

    isa_ok( my $i = SubCB->new, "SubCB" );

    can_ok( $i, "foo" );
    is( eval { $i->foo }, "overridden", "overridden foo from SubCA, not RootC" );

    ok( SubCE->does("RootC"), "CE does RootC" );
    ok( SubCE->does("SubCD"), "CE does SubCD" );
}

{
    use List::Util qw/shuffle/;

    {
        package Abstract;
        use Moose::Role;

        requires "method";
        
        requires "other";

        sub another { "abstract" }

        package ConcreteA;
        use Moose::Role;
        with "Abstract";

        sub other {
            "concrete a";
        };

        package ConcreteB;
        use Moose::Role;
        with "Abstract";

        sub method {
            "concrete b";
        }

        package ConcreteC;
        use Moose::Role;
        with "ConcreteA";

        override other => sub {
            return ( super() . " + c" );
        };

        package SimpleClassWithSome;
        use Moose;

        eval { with ::shuffle qw/ConcreteA ConcreteB/ };
        ::ok( !$@, "simple composition without abstract" ) || ::diag $@;

        package SimpleClassWithAll;
        use Moose;

        eval { with ::shuffle qw/ConcreteA ConcreteB Abstract/ };
        ::ok( !$@, "simple composition with abstract" ) || ::diag $@;
    }

    foreach my $class (qw/SimpleClassWithSome SimpleClassWithAll/) {
        foreach my $role (qw/Abstract ConcreteA ConcreteB/) {
            ok( $class->does($role), "$class does $role");
        }

        foreach my $method (qw/method other another/) {
            can_ok( $class, $method );
        }

        is( eval { $class->another }, "abstract", "provided by abstract" );
        is( eval { $class->other }, "concrete a", "provided by concrete a" );
        is( eval { $class->method }, "concrete b", "provided by concrete b" );
    }        

    {
        package ClassWithSome;
        use Moose;
        
        eval { with ::shuffle qw/ConcreteC ConcreteB/ };
        ::ok( !$@, "composition without abstract" ) || ::diag $@;

        package ClassWithAll;
        use Moose;

        eval { with ::shuffle qw/ConcreteC Abstract ConcreteB/ };
        ::ok( !$@, "composition with abstract" ) || ::diag $@;

        package ClassBad;
        use Moose;

        eval { with ::shuffle qw/ConcreteC Abstract ConcreteA ConcreteB/ }; # this should clash
        ::ok( $@, "can't compose ConcreteA and ConcreteC together" );
    }

    foreach my $class (qw/ClassWithSome ClassWithAll/) {
        foreach my $role (qw/Abstract ConcreteA ConcreteB ConcreteC/) {
            ok( $class->does($role), "$class does $role");
        }

        foreach my $method (qw/method other another/) {
            can_ok( $class, $method );
        }

        is( eval { $class->another }, "abstract", "provided by abstract" );
        is( eval { $class->other }, "concrete a + c", "provided by concrete c + a" );
        is( eval { $class->method }, "concrete b", "provided by concrete b" );
    }
}
