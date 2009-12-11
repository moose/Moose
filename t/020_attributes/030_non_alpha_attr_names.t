use strict;
use warnings;

use Test::More;

{
    package Foo;
    use Moose;
    has 'type' => (
        required => 0,
        reader   => 'get_type',
        default  => 1,
    );

    has '@type' => (
        required => 0,
        reader   => 'get_at_type',
        default  => 2,
    );

    has 'has spaces' => (
        required => 0,
        reader   => 'get_hs',
        default  => 42,
    );

    no Moose;
}

{
    my $foo = Foo->new;

    ok( Foo->meta->has_attribute($_), "Foo has '$_' attribute" )
        for 'type', '@type', 'has spaces';

    is( $foo->get_type,    1,  q{'type' attribute default is 1} );
    is( $foo->get_at_type, 2,  q{'@type' attribute default is 1} );
    is( $foo->get_hs,      42, q{'has spaces' attribute default is 42} );

    Foo->meta->make_immutable, redo if Foo->meta->is_mutable;
}

done_testing;
