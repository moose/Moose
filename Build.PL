use Module::Build;

use strict;
use warnings;

# Scalar::Util 1.18 doesn't work on Windows
my $win32 = !! ( $^O eq 'Win32' or $^O eq 'cygwin' );

my $build = Module::Build->new(
    module_name => 'Moose',
    license => 'perl',
    requires => {
        'Scalar::Util'       => $win32 ? '1.17' : '1.18',
        'Carp'               => '0',
        'Class::MOP'         => '0.39',
        'Sub::Name'          => '0.02',
        'Sub::Exporter'      => '0.972',   
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

