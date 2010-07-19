use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Moose;

{
    package Foo;

    use Moose::Deprecated -api_version => '1.08';
    use Moose;

    has x => (
        is     => 'rw',
        isa    => 'HashRef',
        coerce => 1,
    );
}

with_immutable {
    lives_ok { Foo->new( x => {} ) }
    'Setting coerce => 1 without a coercion on the type does not cause an error in the constructor';

    lives_ok { Foo->new->x( {} ) }
    'Setting coerce => 1 without a coercion on the type does not cause an error when setting the attribut';

    lives_ok { Foo->new( x => 42 ) } 'asasf';
}
'Foo';

done_testing;
