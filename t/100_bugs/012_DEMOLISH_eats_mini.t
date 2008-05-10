#!/usr/bin/perl

use strict;
use warnings;

use Test::More no_plan => 1;
use Test::Exception;

BEGIN {
     use_ok('Moose');
     use_ok('Moose::Util::TypeConstraints');
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
    }
}

my $obj = eval { Foo->new; };
::like( $@, qr/is required/, "... Foo plain" );
::is( $obj, undef, "... the object is undef" );

1;

