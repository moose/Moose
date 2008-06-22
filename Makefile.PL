use strict;
use warnings;
use inc::Module::Install 0.75;

name 'Moose';
all_from 'lib/Moose.pm';
license 'perl';

# Scalar::Util 1.18 doesn't work on Windows
my $win32 = !! ( $^O eq 'Win32' or $^O eq 'cygwin' );

# prereqs
requires 'Scalar::Util' => $win32 ? '1.17' : '1.18';
requires 'Carp';
requires 'Class::MOP'    => '0.59';
requires 'Sub::Exporter' => '0.972';

# only used by oose.pm, not Moose.pm :P
requires 'Filter::Simple' => '0'; 

# things the tests need
build_requires 'Test::More'      => '0.62';
build_requires 'Test::Exception' => '0.21';
build_requires 'Test::LongString';

tests_recursive;

auto_install;

WriteAll();

