#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;

BEGIN {
    use_ok('Moose');
}

{
    package My::Meta;

    use Moose;

    extends 'Moose::Meta::Class';

    has 'meta_size' =>
        ( is  => 'rw',
          isa => 'Int',
        );
}

lives_ok { My::Meta->meta()->make_immutable() } 'can make a meta class immutable';

