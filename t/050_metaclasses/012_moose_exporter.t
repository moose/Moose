#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;

# All the BEGIN blocks are necessary to emulate the behavior of
# loading modules via use and the similar compile-time effect of "no
# ..."
{
    package MooseX::Empty;

    use Moose ();
    BEGIN { Moose::Exporter->build_import_methods( also => 'Moose' ); }
}

{
    package WantsMoose;

    BEGIN { MooseX::Empty->import(); }

    sub foo { 1 }

    BEGIN {
        ::can_ok( 'WantsMoose', 'has' );
        ::can_ok( 'WantsMoose', 'with' );
        ::can_ok( 'WantsMoose', 'foo' );
    }

    BEGIN{ MooseX::Empty->unimport();}
}

{
    ok( ! WantsMoose->can('has'),  'WantsMoose::has() has been cleaned' );
    ok( ! WantsMoose->can('with'), 'WantsMoose::with() has been cleaned' );
    can_ok( 'WantsMoose', 'foo' );
}

{
    package MooseX::Sugar;

    use Moose ();

    sub wrapped1 {
        my $caller = shift;
        return $caller . ' called wrapped1';
    }

    BEGIN {
        Moose::Exporter->build_import_methods(
            with_caller => ['wrapped1'],
            also        => 'Moose',
        );
    }
}

{
    package WantsSugar;

    BEGIN { MooseX::Sugar->import() }

    sub foo { 1 }

    BEGIN {
        ::can_ok( 'WantsSugar', 'has' );
        ::can_ok( 'WantsSugar', 'with' );
        ::can_ok( 'WantsSugar', 'wrapped1' );
        ::can_ok( 'WantsSugar', 'foo' );
        ::is( wrapped1(), 'WantsSugar called wrapped1',
              'wrapped1 identifies the caller correctly' );
    }

    BEGIN{ MooseX::Sugar->unimport();}
}

{
    ok( ! WantsSugar->can('has'),  'WantsSugar::has() has been cleaned' );
    ok( ! WantsSugar->can('with'), 'WantsSugar::with() has been cleaned' );
    ok( ! WantsSugar->can('wrapped1'), 'WantsSugar::wrapped1() has been cleaned' );
    can_ok( 'WantsSugar', 'foo' );
}

{
    package MooseX::MoreSugar;

    use Moose ();

    sub wrapped2 {
        my $caller = shift;
        return $caller . ' called wrapped2';
    }

    sub as_is1 {
        return 'as_is1';
    }

    BEGIN {
        Moose::Exporter->build_import_methods(
            with_caller => ['wrapped2'],
            as_is       => ['as_is1'],
            also        => 'MooseX::Sugar',
        );
    }
}

{
    package WantsMoreSugar;

    BEGIN { MooseX::MoreSugar->import() }

    sub foo { 1 }

    BEGIN {
        ::can_ok( 'WantsMoreSugar', 'has' );
        ::can_ok( 'WantsMoreSugar', 'with' );
        ::can_ok( 'WantsMoreSugar', 'wrapped1' );
        ::can_ok( 'WantsMoreSugar', 'wrapped2' );
        ::can_ok( 'WantsMoreSugar', 'as_is1' );
        ::can_ok( 'WantsMoreSugar', 'foo' );
        ::is( wrapped1(), 'WantsMoreSugar called wrapped1',
              'wrapped1 identifies the caller correctly' );
        ::is( wrapped2(), 'WantsMoreSugar called wrapped2',
              'wrapped2 identifies the caller correctly' );
        ::is( as_is1(), 'as_is1',
              'as_is1 works as expected' );
    }

    BEGIN{ MooseX::MoreSugar->unimport();}
}

{
    ok( ! WantsMoreSugar->can('has'),  'WantsMoreSugar::has() has been cleaned' );
    ok( ! WantsMoreSugar->can('with'), 'WantsMoreSugar::with() has been cleaned' );
    ok( ! WantsMoreSugar->can('wrapped1'), 'WantsMoreSugar::wrapped1() has been cleaned' );
    ok( ! WantsMoreSugar->can('wrapped2'), 'WantsMoreSugar::wrapped2() has been cleaned' );
    ok( ! WantsMoreSugar->can('as_is1'), 'WantsMoreSugar::as_is1() has been cleaned' );
    can_ok( 'WantsMoreSugar', 'foo' );
}

{
    package MooseX::CircularAlso;

    use Moose ();

    ::dies_ok(
        sub {
            Moose::Exporter->build_import_methods(
                also => [ 'Moose', 'MooseX::CircularAlso' ],
            );
        },
        'a circular reference in also dies with an error'
    );

    ::like(
        $@,
        qr/\QCircular reference in also parameter to MooseX::Exporter between MooseX::CircularAlso and MooseX::CircularAlso/,
        'got the expected error from circular reference in also'
    );
}

{
    package MooseX::CircularAlso;

    use Moose ();

    ::dies_ok(
        sub {
            Moose::Exporter->build_import_methods(
                also => [ 'NoSuchThing' ],
            );
        },
        'a package which does not use Moose::Exporter in also dies with an error'
    );

    ::like(
        $@,
        qr/\QPackage in also (NoSuchThing) does not seem to use MooseX::Exporter/,
        'got the expected error from a reference in also to a package which does not use Moose::Exporter'
    );
}
