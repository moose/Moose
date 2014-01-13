use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;

{
    package Custom::Trait;
    use Moose::Role;

    my $alias = "Trait1";
    my $new_role_name = __PACKAGE__ . "::$alias";
    Moose::Meta::Role->initialize($new_role_name);
    Moose::Exporter->setup_import_methods(exporting_package => $new_role_name);
    Moose::Util::meta_attribute_alias($alias, $new_role_name);
}

lives_ok {
    {
        package Foo;
        use Moose;
        use Custom::Trait;

        has field1 => (is => 'rw', traits => [qw{Trait1}]);
    }
    Foo->new;
} 'Custom trait discovered';

dies_ok {
    {
        package Bar;
        use Moose;
        use Custom::Trait;

        has field1 => (is => 'rw', traits => [qw{UndeclaredTrait}]);
    }
    Bar->new;
} 'Undeclared traits still throw errors';
