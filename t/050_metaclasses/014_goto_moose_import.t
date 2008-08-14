#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;

# Some packages out in the wild cooperate with Moose by using goto
# &Moose::import. we want to make sure it still works.

{
    package MooseAlike1;

    use strict;
    use warnings;

    use Moose ();

    sub import {
        goto &Moose::import;
    }
}

{
    package Foo;

    MooseAlike1->import();

    ::lives_ok( sub { has( 'size' ) },
                'has was exported via MooseAlike1' );
}

{
    package MooseAlike2;

    use strict;
    use warnings;

    use Moose ();

    my $import = \&Moose::import;
    sub import {
        goto $import;
    }
}

{
    package Bar;

    MooseAlike2->import();

    ::lives_ok( sub { has( 'size' ) },
                'has was exported via MooseAlike2' );
}




