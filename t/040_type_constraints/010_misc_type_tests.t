#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;

BEGIN {
    use_ok('Moose::Util::TypeConstraints');           
}

# subtype 'aliasing' ...

lives_ok {
    subtype 'Numb3rs' => as 'Num';
} '... create bare subtype fine';

my $numb3rs = find_type_constraint('Numb3rs');
isa_ok($numb3rs, 'Moose::Meta::TypeConstraint');