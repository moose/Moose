#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;

BEGIN {
     use_ok('Moose');
}

{
    package Foo;
    use Moose;

    has 'bar' => (
        is       => 'ro',
        required => 1,
    );

    # Defining this causes the FIRST call to Baz->new w/o param to fail,
    # if no call to ANY Moose::Object->new was done before.
    sub DEMOLISH {
        my ( $self ) = @_;
        # ... Moose (kinda) eats exceptions in DESTROY/DEMOLISH";    
    }
}

{
    my $obj = eval { Foo->new; };
    ::like( $@, qr/is required/, "... Foo plain" );
    ::is( $obj, undef, "... the object is undef" );
}

{
    package Bar;
    
    sub new { die "Bar died"; }

    sub DESTROY {
        die "Vanilla Perl eats exceptions in DESTROY too";
    }
}

{
    my $obj = eval { Bar->new; };
    ::like( $@, qr/Bar died/, "... Bar plain" );
    ::is( $obj, undef, "... the object is undef" );
}

1;

