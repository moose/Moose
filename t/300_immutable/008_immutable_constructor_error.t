#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;

BEGIN {
    use_ok('Moose');
}

=pod

This tests to make sure that we provide the same error messages from
an immutable constructor as is provided by a non-immutable
constructor.

=cut

{
    package Foo;
    use Moose;

    has 'foo' => (is => 'rw', isa => 'Int');

    Foo->meta->make_immutable(debug => 0);
}

my $scalar = 1;
throws_ok { Foo->new($scalar) } qr/\QSingle parameters to new() must be a HASH ref/,
          'Non-ref provided to immutable constructor gives useful error message';
throws_ok { Foo->new(\$scalar) } qr/\QSingle parameters to new() must be a HASH ref/,
          'Scalar ref provided to immutable constructor gives useful error message';

