use strict;
use warnings;
use inc::Module::Install;
use 5.008001;

check_conflicts();

name 'Moose';
perl_version '5.008001';
all_from 'lib/Moose.pm';
license 'perl';

requires 'Scalar::Util'     => '1.19';
requires 'Carp';
requires 'Class::MOP'       => '0.92';
requires 'List::MoreUtils'  => '0.12';
requires 'Sub::Exporter'    => '0.980';
requires 'Task::Weaken'     => '0';
requires 'Data::OptList'    => '0';
requires 'Sub::Name'        => '0';

test_requires 'Test::More'      => '0.77';
test_requires 'Test::Exception' => '0.27';

if ( -d '.svn' || -d '.git' || $ENV{IS_MAINTAINER} ) {
    system( $^X, 'author/extract-inline-tests' );
}

extra_tests();
tests_recursive();

WriteAll();

# Use the cpan-smolder-stable script in the Moose svn root to figure
# out what on CPAN will break with the latest Moose, then update this
# before a release.
sub check_conflicts {
    my %conflicts = (
        'MooseX::ClassAttribute'    => '0.09',
        'MooseX::Singleton'         => '0.17',
        'MooseX::StrictConstructor' => '0.07',
        'MooseX::Params::Validate'  => '0.05',
        'Fey::ORM'                  => '0.23',
    );

    my $found = 0;
    for my $mod ( sort keys %conflicts ) {
        eval "require $mod";
        next if $@;

        my $installed = $mod->VERSION();
        if ( $installed le $conflicts{$mod} ) {

            print <<"EOF";

***
    This version of Moose conflicts with the version of
    $mod ($installed) you have installed.

    You will need to upgrade $mod after installing
    this version of Moose.
***

EOF

            $found = 1;
        }
    }

    return unless $found;

    # More or less copied from Module::Build
    return if  $ENV{PERL_MM_USE_DEFAULT};
    return unless -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT));

    sleep 4;
}
