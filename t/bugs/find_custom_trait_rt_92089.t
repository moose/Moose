use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    package Custom::Trait;
    use Moose::Role;

    my $alias         = 'Trait1';
    my $new_role_name = __PACKAGE__ . "::$alias";
    Moose::Meta::Role->initialize($new_role_name);
    Moose::Exporter->setup_import_methods(
        exporting_package => $new_role_name );
    Moose::Util::meta_attribute_alias( $alias, $new_role_name );
}

is(
    exception {
        package Foo;
        use Moose;
        use Custom::Trait;

        has field1 => ( is => 'rw', traits => [qw{Trait1}] );

        Foo->new;
    },
    undef,
    'Trait that is not an on-disk role works'
);

like(
    exception {
        package Bar;
        use Moose;
        use Custom::Trait;

        has field1 => ( is => 'rw', traits => [qw{UndeclaredTrait}] );
        Bar->new;
    },
    qr/\QCan't locate Moose::Meta::Attribute::Custom::Trait::UndeclaredTrait or UndeclaredTrait/,
    'Traits with no alias or package cause an exception'
);

done_testing();
