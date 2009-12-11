use strict;
use warnings;
{
    package ParentClass;
    use Moose;
}
{
    package SomeClass;
    use base 'ParentClass';
}
{
    package SubClassUseBase;
    use base qw/SomeClass/;
    use Moose;
}

use Test::More;
use Test::Exception;

lives_ok {
    Moose->init_meta(for_class => 'SomeClass');
} 'Moose class => use base => Moose Class, then Moose->init_meta on middle class ok';

done_testing;
