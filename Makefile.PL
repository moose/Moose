use strict;
use warnings;
use inc::Module::Install 0.98;
use Module::Install::AuthorRequires;
use Module::Install::ExtraTests;
use 5.008003;

check_broken_extratests();
check_conflicts();

name 'Moose';
perl_version '5.008003';
all_from 'lib/Moose.pm';
license 'perl';

requires 'Carp';
requires 'Class::MOP'                  => '1.10';
requires 'Data::OptList'               => '0';
requires 'List::MoreUtils'             => '0.12';
requires 'Package::DeprecationManager' => '0.07';
requires 'Params::Util'                => '1.00';
requires 'Scalar::Util'                => '1.19';
requires 'Sub::Exporter'               => '0.980';
requires 'Sub::Name'                   => '0';
requires 'Task::Weaken'                => '0';
requires 'Try::Tiny'                   => '0.02';

test_requires 'Test::More'      => '0.88';
test_requires 'Test::Exception' => '0.27';
test_requires 'Test::Requires'  => '0.05';

author_requires 'DateTime';
author_requires 'DateTime::Calendar::Mayan';
author_requires 'DateTime::Format::MySQL';
author_requires 'Declare::Constraints::Simple';
author_requires 'DBM::Deep';
author_requires 'File::Find::Rule';
author_requires 'HTTP::Headers';
author_requires 'IO::File';
author_requires 'IO::String';
author_requires 'Locale::US';
author_requires 'Module::Info';
author_requires 'Module::Refresh';
author_requires 'Params::Coerce';
author_requires 'Regexp::Common';
author_requires 'Test::Deep';
author_requires 'Test::Inline';
author_requires 'Test::NoTabs';
author_requires 'Test::Output';
author_requires 'Test::Pod::Coverage';
author_requires 'Test::Spelling';
author_requires 'URI';

if ( is_maintainer() ) {
    system( $^X, 'author/extract-inline-tests' );
}

tests_recursive();

repository 'git://git.moose.perl.org/Moose.git';
add_metadata(x_authority => 'cpan:STEVAN');

extra_tests();

WriteAll();

# Use the xt/author/test-my-dependents.t test to figure
# out what on CPAN will break with the latest Moose, then update this
# before a release.
sub check_conflicts {
    my %conflicts = (
        'Catalyst'                       => '5.80028',
        'Devel::REPL'                    => '1.003008',
        'Fey'                            => '0.36',
        'Fey::ORM'                       => '0.34',
        'File::ChangeNotify'             => '0.15',
        'KiokuDB'                        => '0.49',
        'Markdent'                       => '0.16',
        'MooseX::Aliases'                => '0.07',
        'MooseX::AlwaysCoerce'           => '0.05',
        'MooseX::AttributeHelpers'       => '0.22',
        'MooseX::AttributeInflate'       => '0.02',
        'MooseX::Attribute::Prototype'   => '0.10',
        'MooseX::ClassAttribute'         => '0.17',
        'MooseX::FollowPBP'              => '0.02',
        'MooseX::HasDefaults'            => '0.02',
        'MooseX::InstanceTracking'       => '0.04',
        'MooseX::LazyRequire'            => '0.05',
        'MooseX::MethodAttributes'       => '0.22',
        'MooseX::NonMoose'               => '0.15',
        'MooseX::Params::Validate'       => '0.05',
        'MooseX::POE'                    => '0.205',
        'MooseX::Role::Cmd'              => '0.06',
        'MooseX::Role::WithOverloading'  => '0.07',
        'MooseX::SemiAffordanceAccessor' => '0.05',
        'MooseX::Singleton'              => '0.24',
        'MooseX::StrictConstructor'      => '0.08',
        'MooseX::Types'                  => '0.19',
        'MooseX::UndefTolerant'          => '0.04',
        'namespace::autoclean'           => '0.08',
        'Pod::Elemental'                 => '0.093280',
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
