#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;


{
    package My::Meta;

    use Moose;

    extends 'Moose::Meta::Class';

    has 'meta_size' => (
        is  => 'rw',
        isa => 'Int',
    );
}

lives_ok {
    My::Meta->meta()->make_immutable(debug => 0)
} '... can make a meta class immutable';

done_testing;
