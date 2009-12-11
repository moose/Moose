#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Moose ();

BEGIN {
    use_ok('Moose::Meta::Attribute::Native');
    use_ok('Moose::Meta::Attribute::Native::Trait::Bool');
    use_ok('Moose::Meta::Attribute::Native::Trait::Hash');
    use_ok('Moose::Meta::Attribute::Native::Trait::Array');
    use_ok('Moose::Meta::Attribute::Native::Trait::Counter');
    use_ok('Moose::Meta::Attribute::Native::Trait::Number');
    use_ok('Moose::Meta::Attribute::Native::Trait::String');
}

done_testing;
