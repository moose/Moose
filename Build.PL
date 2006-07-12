use Module::Build;

use strict;

my $build = Module::Build->new(
    module_name => 'Moose',
    license => 'perl',
    requires => {
        'Scalar::Util'       => '1.18',
        'Carp'               => '0',
        'Class::MOP'         => '0.30',
        'Sub::Name'          => '0.02',
        'UNIVERSAL::require' => '0.10',
        'Sub::Exporter'      => '0.954',
        'Sub::Install'       => '0.92',   
        'B'                  => '0',             
    },
    optional => {
    },
    build_requires => {
        'Test::More'       => '0.62',
        'Test::Exception'  => '0.21',
        'Test::LongString' => '0',
    },
    create_makefile_pl => 'traditional',
    recursive_test_files => 1,
    add_to_cleanup => [
        'META.yml', '*.bak', '*.gz', 'Makefile.PL',
    ],
);

$build->create_build_script;

