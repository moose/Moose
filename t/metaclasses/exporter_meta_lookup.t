#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    package Class::Vacuum::Innards;
    use Moose;

    package Class::Vacuum;
    use Moose ();
    use Moose::Exporter;

    BEGIN {
        Moose::Exporter->setup_import_methods(
            also        => 'Moose',
            meta_lookup => sub { Class::MOP::class_of('Class::Vacuum::Innards') },
        );
    }
}

{
    package Victim;
    BEGIN { Class::Vacuum->import };

    has star_rod => (
        is => 'ro',
    );
}

ok(Class::Vacuum::Innards->can('star_rod'), 'Vacuum stole the star_rod method');
ok(!Victim->can('star_rod'), 'Victim does not get it at all');

done_testing;

