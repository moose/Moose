use strict;
use warnings;
use inc::Module::Install 0.95;
use Module::Install::AuthorRequires;
use 5.008001;

check_broken_extratests();
check_conflicts();

name 'Moose';
perl_version '5.008001';
all_from 'lib/Moose.pm';
license 'perl';

requires 'Carp';
requires 'Class::MOP'       => '0.98';
requires 'Data::OptList'    => '0';
requires 'List::MoreUtils'  => '0.12';
requires 'Scalar::Util'     => '1.19';
requires 'Sub::Exporter'    => '0.980';
requires 'Sub::Name'        => '0';
requires 'Task::Weaken'     => '0';
requires 'Try::Tiny'        => '0.02';

test_requires 'Test::More'      => '0.88';
test_requires 'Test::Exception' => '0.27';

author_requires 'Test::Inline';
author_requires 'File::Find::Rule';
author_requires 'Module::Info';
author_requires 'Test::Spelling';
author_requires 'Test::Pod::Coverage';
author_requires 'Test::NoTabs';

if ( is_maintainer() ) {
    system( $^X, 'author/extract-inline-tests' );
}

tests_recursive();

WriteAll();

# Use the cpan-smolder-stable script in the Moose svn root to figure
# out what on CPAN will break with the latest Moose, then update this
# before a release.
sub check_conflicts {
    my %conflicts = (
        'Devel::REPL'                   => '1.003008',
        'Fey::ORM'                      => '0.23',
        'Catalyst'                      => '5.80017',
        'MooseX::Aliases'               => '0.07',
        'MooseX::AttributeHelpers'      => '0.22',
        'MooseX::Attribute::Prototype'  => '0.10',
        'MooseX::ClassAttribute'        => '0.09',
        'MooseX::MethodAttributes'      => '0.18',
        'MooseX::NonMoose'              => '0.05',
        'MooseX::Params::Validate'      => '0.05',
        'MooseX::Role::Cmd'             => '0.06',
        'MooseX::Role::WithOverloading' => '0.04',
        'MooseX::Singleton'             => '0.19',
        'MooseX::StrictConstructor'     => '0.07',
        'MooseX::Types'                 => '0.19',
        'namespace::autoclean'          => '0.08',
        'KiokuDB'                       => '0.41',
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

sub is_maintainer {
    return $Module::Install::AUTHOR || $ENV{IS_MAINTAINER};
}

sub check_broken_extratests {
    return unless is_maintainer();

    if ( exists $Module::Install::ExtraTests::{VERSION} && Module::Install::ExtraTests->VERSION < 0.007 ) {
        print STDERR <<'EOR';
You have a broken version of Module::Install::ExtraTests installed.
Please upgrade to version 0.007 or newer and re-run Makefile.PL
EOR
        exit 0;
    }
}
