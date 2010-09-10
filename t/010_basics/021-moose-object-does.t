use strict;
use warnings;

use Test::More;
use Test::Moose;

{
    package Role::A;

    use Moose::Role
}

{
    package Role::B;

    use Moose::Role
}

{
    package Foo;

    use Moose;
}

{
    package Bar;

    use Moose;

    with 'Role::A';
}

{
    package Baz;

    use Moose;

    with qw( Role::A Role::B );
}

with_immutable {

    for my $thing ( 'Foo', Foo->new ) {
        my $name = ref $thing ? 'Foo object' : 'Foo class';
        $name .= ' (immutable)' if $thing->meta->is_immutable;

        ok(
            !$thing->does('Role::A'),
            "$name does not do Role::A"
        );
        ok(
            !$thing->does('Role::B'),
            "$name does not do Role::B"
        );

        ok(
            !$thing->does( Role::A->meta ),
            "$name does not do Role::A (passed as object)"
        );
        ok(
            !$thing->does( Role::B->meta ),
            "$name does not do Role::B (passed as object)"
        );

        ok(
            !$thing->DOES('Role::A'),
            "$name does not do Role::A (using DOES)"
        );
        ok(
            !$thing->DOES('Role::B'),
            "$name does not do Role::B (using DOES)"
        );
    }

    for my $thing ( 'Bar', Bar->new ) {
        my $name = ref $thing ? 'Bar object' : 'Bar class';
        $name .= ' (immutable)' if $thing->meta->is_immutable;

        ok(
            $thing->does('Role::A'),
            "$name does Role::A"
        );
        ok(
            !$thing->does('Role::B'),
            "$name does not do Role::B"
        );

        ok(
            $thing->does( Role::A->meta ),
            "$name does Role::A (passed as object)"
        );
        ok(
            !$thing->does( Role::B->meta ),
            "$name does not do Role::B (passed as object)"
        );

        ok(
            $thing->DOES('Role::A'),
            "$name does Role::A (using DOES)"
        );
        ok(
            !$thing->DOES('Role::B'),
            "$name does not do Role::B (using DOES)"
        );
    }

    for my $thing ( 'Baz', Baz->new ) {
        my $name = ref $thing ? 'Baz object' : 'Baz class';
        $name .= ' (immutable)' if $thing->meta->is_immutable;

        ok(
            $thing->does('Role::A'),
            "$name does Role::A"
        );
        ok(
            $thing->does('Role::B'),
            "$name does Role::B"
        );

        ok(
            $thing->does( Role::A->meta ),
            "$name does Role::A (passed as object)"
        );
        ok(
            $thing->does( Role::B->meta ),
            "$name does Role::B (passed as object)"
        );

        ok(
            $thing->DOES('Role::A'),
            "$name does Role::A (using DOES)"
        );
        ok(
            $thing->DOES('Role::B'),
            "$name does Role::B (using DOES)"
        );
    }

}
qw( Foo Bar Baz );

done_testing;
