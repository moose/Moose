use strict;
use warnings;
{
    package ParentClass;
    use Moose;
}
{
    package SomeClass;
    use parent -norequire => 'ParentClass';
}
{
    package SubClassUseBase;
    use parent -norequire => 'SomeClass';
    use Moose;
}

use Test::More;
use Test::Fatal;

is( exception {
    Moose->init_meta(for_class => 'SomeClass');
}, undef, 'Moose class => use parent => Moose Class, then Moose->init_meta on middle class ok' );

done_testing;
