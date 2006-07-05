#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib', 'lib';

use Test::More tests => 6;

BEGIN {
    use_ok('Moose');           
}

{
    package Bar;
    use Moose;
    
    eval { extends 'Foo'; };
    ::ok(!$@, '... loaded Foo superclass correctly');
}

{
    package Baz;
    use Moose;
    
    eval { extends 'Bar'; };
    ::ok(!$@, '... loaded (inline) Bar superclass correctly');
}

{
    package Foo::Bar;
    use Moose;
    
    eval { extends 'Foo', 'Bar'; };
    ::ok(!$@, '... loaded Foo and (inline) Bar superclass correctly');
}

{
    package Bling;
    use Moose;
    
    eval { extends 'No::Class'; };
    ::ok($@, '... could not find the superclass (as expected)');
    ::like($@, qr/^Could not load module 'No\:\:Class' because \:/, '... and got the error we expected');
}

