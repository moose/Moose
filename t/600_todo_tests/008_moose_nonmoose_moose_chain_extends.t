use strict;
use warnings;
use Test::More tests => 1;

{
    package My::Role;
    use Moose::Role;
}
{
    package SomeClass;
    use Moose -traits => 'My::Role';
}
{
    package SubClassUseBase;
    use base qw/SomeClass/;
}
{
    package SubSubClassUseBase;
    use Moose;
    use Test::More;
    use Test::Exception;
    TODO: {
        local $TODO = 'Metaclass incompatibility';
        lives_ok {
            extends 'SubClassUseBase';
        } 'Can extend non-moose class whos parent class is a Moose class with a meta role';
    }
}

