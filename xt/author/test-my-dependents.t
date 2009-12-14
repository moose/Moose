use strict;
use warnings;

use Cwd qw( abs_path );
use Test::More;

plan skip_all => 'This test will not run unless you set MOOSE_TEST_MD to a true value'
    unless $ENV{MOOSE_TEST_MD};

eval 'use Test::DependentModules qw( test_all_dependents );';
plan skip_all => 'This test requires Test::DependentModules'
    if $@;

$ENV{PERL_TEST_DM_LOG_DIR} = abs_path('.');

my $exclude = qr/^Acme-/x;

test_all_dependents( 'Moose', { exclude => $exclude } );
