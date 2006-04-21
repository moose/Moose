#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;

BEGIN {
    use_ok('Moose');           
}

{
    package Foo;
    use strict;
    use warnings;
    use Moose;
    
    has 'bar' => (is => 'rw', isa => 'ArrayRef | HashRef');
}

my $foo = Foo->new;
isa_ok($foo, 'Foo');

lives_ok {
    $foo->bar([])
} '... set bar successfully with an ARRAY ref';

lives_ok {
    $foo->bar({})
} '... set bar successfully with a HASH ref';

dies_ok {
    $foo->bar(100)
} '... couldnt set bar successfully with a number';

dies_ok {
    $foo->bar(sub {})
} '... couldnt set bar successfully with a CODE ref';

# check the constructor

lives_ok {
    Foo->new(bar => [])
} '... created new Foo with bar successfully set with an ARRAY ref';

lives_ok {
    Foo->new(bar => {})
} '... created new Foo with bar successfully set with a HASH ref';

dies_ok {
    Foo->new(bar => 50)
} '... didnt create a new Foo with bar as a number';

dies_ok {
    Foo->new(bar => sub {})
} '... didnt create a new Foo with bar as a number';


