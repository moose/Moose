use strict;
use warnings;

use Test::More;
use Test::Exception;
use Moose::Util qw( add_method_modifier );

my $COUNT = 0;
{
    package Foo;
    use Moose;

    sub foo { }
    sub bar { }
}

lives_ok {
    add_method_modifier('Foo', 'before', [ ['foo', 'bar'], sub { $COUNT++ } ]);
} 'method modifier with an arrayref';

dies_ok {
    add_method_modifier('Foo', 'before', [ {'foo' => 'bar'}, sub { $COUNT++ } ]);
} 'method modifier with a hashref';

my $foo = Foo->new;
$foo->foo;
$foo->bar;
is($COUNT, 2, "checking that the modifiers were installed.");


done_testing;
