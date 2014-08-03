use strict;
use warnings;

use Test::CleanNamespaces;
use Test::More;

{
    package Metarole;
    use Moose::Role;
}

{
    package Foo;
    use Moose ();
    use Moose::Exporter;
    {
        local $@;
        eval 'use namespace::autoclean; $::HAS_NC_AC = 1';
    }

    Moose::Exporter->setup_import_methods(
        also            => 'Moose',
        class_metaroles => { class => ['Metarole'] },
    );

    my $meta = Class::MOP::Package->initialize(__PACKAGE__);
    for my $name (qw( import unimport init_meta )) {
        my $body = $meta->get_package_symbol( '&' . $name );
        my ( $package, $sub_name ) = Class::MOP::get_code_info($body);

        ::is( $package, __PACKAGE__, "$name sub is in Foo package" );
        ::is( $sub_name, $name, "$name sub has that name, not __ANON__" );
    }
}

if ($::HAS_NC_AC) {
    $INC{'Foo.pm'} = 1;
    namespaces_clean('Foo');
}

done_testing();

