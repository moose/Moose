#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;

BEGIN {
    use_ok('Moose');           
}

=pod

http://www.gwydiondylan.org/books/drm/Instance_Creation_and_Initialization#HEADING43-37

=cut

{
    package Foo;
    use strict;
    use warnings;
    use Moose;
    
    has 'bar' => (is => 'ro', isa => 'Str', default => 'Foo::bar');
    
    package Bar;
    use strict;
    use warnings;
    use Moose;
    
    extends 'Foo';
    
    has '+bar' => (default => 'Bar::bar');  
}

my $foo = Foo->new;
isa_ok($foo, 'Foo');

is($foo->bar, 'Foo::bar', '... got the right default value');

dies_ok { $foo->bar(10) } '... Foo::bar is a read/only attr';

my $bar = Bar->new;
isa_ok($bar, 'Bar');
isa_ok($bar, 'Foo');

is($bar->bar, 'Bar::bar', '... got the right default value');

dies_ok { $bar->bar(10) } '... Bar::bar is a read/only attr';

# check some meta-stuff

ok(Bar->meta->has_attribute('bar'), '... Bar has a bar attr');
isnt(Foo->meta->get_attribute('bar'), 
     Bar->meta->get_attribute('bar'), 
     '... Foo and Bar have different copies of bar');









