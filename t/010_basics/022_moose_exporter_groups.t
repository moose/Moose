#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 45;
use Test::Exception;

{
    package ExGroups1;
    use Moose::Exporter;
    use Moose ();

    Moose::Exporter->setup_import_methods(
        also        => ['Moose'],
        with_meta   => ['with_meta1'],
        with_caller => ['default_export1'],
        as_is       => ['default_export2'],
        groups      => { all_group  => [':all'], 
                         just_one   => ['default_export1'] }
    );

    sub default_export1 { 1 }
    sub default_export2 { 2 }

    sub with_meta1 (&) {
        my ($meta, $code) = @_;
        return $meta;
    }
}

{
    package UseAllGroup;
    
    ExGroups1->import(':all_group');

    ::can_ok( __PACKAGE__, 'with_meta1' );
    ::can_ok( __PACKAGE__, 'default_export1' );
    ::can_ok( __PACKAGE__, 'default_export2' );
    ::can_ok( __PACKAGE__, 'has' );

    my $meta;
    eval q/$meta = with_meta1 { return 'coderef'; }/;
    ::is($@, '', 'calling with_meta1 with prototype is not an error');
    ::isa_ok( $meta, 'Moose::Meta::Class', 'with_meta first argument' );
    ::is( prototype( __PACKAGE__->can('with_meta1') ), 
          prototype( ExGroups1->can('with_meta1') ),
    'using correct prototype on with_meta function' );

    ExGroups1->unimport();

    ::ok( ! __PACKAGE__->can('with_meta1'), __PACKAGE__.'::with_meta1() has been cleaned' );
    ::ok( ! __PACKAGE__->can('default_export1'), __PACKAGE__.'::default_export1() has been cleaned' );
    ::ok( ! __PACKAGE__->can('default_export2'), __PACKAGE__.'::default_export2() has been cleaned' );
    ::ok( ! __PACKAGE__->can('has'), __PACKAGE__.'::has() has been cleaned' );
}

{
    package UseJustOne;

    ExGroups1->import(':just_one');

    ::can_ok( __PACKAGE__, 'default_export1' );
    ::ok( ! __PACKAGE__->can('default_export2'), __PACKAGE__.'::default_export2() was not imported' );
    ::ok( ! __PACKAGE__->can('has'), __PACKAGE__.'::has() was not imported' );

    ExGroups1->unimport();

    ::ok( ! __PACKAGE__->can('default_export1'), __PACKAGE__.'::default_export1() has been cleared' );
}

{
    package ExGroups2;
    use Moose::Exporter;
    
    Moose::Exporter->setup_import_methods(
        also        => ['ExGroups1'],
        as_is       => ['exgroups2_as_is'],
        with_caller => ['exgroups2_with_caller'],
        groups      => { default    => ['exgroups2_as_is'],
                         code_group => \&generate_group,
                         parent1    => [qw(:ExGroups1 :code_group)],
                         parent2    => [qw(:all)] }
    );

    sub exgroups2_as_is { 3 }

    sub generate_group {
        my ($caller, $group_name, $args, $context) = @_;

        ::is($group_name, 'code_group', 'original name is passed to group code');
        ::is($args->{install_as}, $caller . '_code', 'group code arguments match caller');
        ::is($context->{from}, __PACKAGE__, 'defined package name is passed to group code');

        return { $args->{install_as} => \&exported_by_group };
    }

    sub exported_by_group (&) {
        my ($caller, $coderef) = @_;
        return $caller;
    }
}

{
    package UseDefault;
    
    ExGroups2->import;

    ::can_ok( __PACKAGE__, 'exgroups2_as_is' );
    ::ok( ! __PACKAGE__->can('exgroups2_with_caller'), '"default" group is no longer "all"' );
}

{
    package UseCodeGroup;

    ExGroups2->import(':code_group', { install_as => (my $export_name = __PACKAGE__.'_code') });

    ::can_ok( __PACKAGE__, $export_name );
    ::ok( &UseCodeGroup_code() eq __PACKAGE__, 'code group exports act like "with_caller" subs' );
    ::lives_ok(sub { UseCodeCodeGroup_code { return 'code block'; } }, 'code group exports keep their prototypes');

    ::ok( ! __PACKAGE__->can('exgroups2_as_is'), 'code group will not automatically export any symbols' );

    ExGroups2->unimport;
    
    ::ok( ! __PACKAGE__->can($export_name), 
        'dynamically-named '. __PACKAGE__."::$export_name() has been cleared" );
}

{
    package UseParent1;

    ExGroups2->import(':parent1', { install_as => (my $export_name = __PACKAGE__.'_code') });

    ::can_ok( __PACKAGE__, $export_name );
    ::can_ok( __PACKAGE__, 'default_export1' );
    ::can_ok( __PACKAGE__, 'default_export2' );
    ::can_ok( __PACKAGE__, 'has' );

    ExGroups2->unimport;

    ::ok( ! __PACKAGE__->can($export_name), __PACKAGE__."::$export_name() has been cleared" );
    ::ok( ! __PACKAGE__->can('default_export1'), __PACKAGE__.'::default_export1() has been cleaned' );
    ::ok( ! __PACKAGE__->can('default_export2'), __PACKAGE__.'::default_export2() has been cleaned' );
    ::ok( ! __PACKAGE__->can('has'), __PACKAGE__.'::has() has been cleaned' );
}

{
    package UseParent2;

    ExGroups2->import(':parent2', { install_as => (my $export_name = __PACKAGE__.'_code') });

    ::ok( ! __PACKAGE__->can($export_name), '"all" group will not call code groups' );
    ::can_ok( __PACKAGE__, 'exgroups2_as_is' );
    ::can_ok( __PACKAGE__, 'exgroups2_with_caller' );
    ::can_ok( __PACKAGE__, 'default_export1' );
    ::can_ok( __PACKAGE__, 'has' );

    ExGroups2->unimport;

    ::ok( ! __PACKAGE__->can('exgroups2_as_is'), __PACKAGE__.'::exgroups2_as_is() has been cleaned' );
    ::ok( ! __PACKAGE__->can('exgroups2_with_caller'), __PACKAGE__.'::exgroups2_with_caller() has been cleaned' );
    ::ok( ! __PACKAGE__->can('default_export1'), __PACKAGE__.'::default_export1() has been cleaned' );
    ::ok( ! __PACKAGE__->can('has'), __PACKAGE__.'::has() has been cleaned' );
}

