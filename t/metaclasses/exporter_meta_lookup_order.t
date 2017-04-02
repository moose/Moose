#!/usr/bin/perl

use strict;
use warnings;

use Test::Fatal;
use Test::More;

my (@expected_call_order, @actual_call_order);

{
    package GreatGrandParent;
    use Moose;
    use Moose::Exporter;
    use Test::More;

    BEGIN {
        push @expected_call_order, __PACKAGE__;

        Moose::Exporter->setup_import_methods(
            also        => 'Moose',
            meta_lookup => sub { Class::MOP::class_of(__PACKAGE__) },
        );
    }

    sub init_meta {
        push @actual_call_order, __PACKAGE__;
    }
}

{
    package GrandParent;
    use Moose;
    use Moose::Exporter;
    use Test::More;

    BEGIN { GreatGrandParent->import() }

    BEGIN {
        push @expected_call_order, (
            'GreatGrandParent',
            __PACKAGE__,
        );

        Moose::Exporter->setup_import_methods(
            also        => 'GreatGrandParent',
            meta_lookup => sub { Class::MOP::class_of(__PACKAGE__) },
        );
    }

    sub init_meta {
        push @actual_call_order, __PACKAGE__;
    }
}

{
    package Parent;
    use Moose;
    use Moose::Exporter;
    use Test::More;

    BEGIN { GrandParent->import() }

    BEGIN {
        push @expected_call_order, (
            'GreatGrandParent',
            'GrandParent',
            __PACKAGE__
        );

        Moose::Exporter->setup_import_methods(
            also        => 'GrandParent',
            meta_lookup => sub { Class::MOP::class_of(__PACKAGE__) },
        );
    }

    sub init_meta {
        push @actual_call_order, __PACKAGE__;
    }
}

{
    package Child;
    use Moose;

    BEGIN { Parent->import() }

    sub init_meta {
        # This init_meta() method is a guard against it being called.
        # It shouldn't be called at all.
        push @actual_call_order, __PACKAGE__;
    }
}

Child->new();

note("Expected call order: @expected_call_order");
note("Actual   call order: @actual_call_order");

is_deeply(
    \@actual_call_order,
    \@expected_call_order,
    "init_meta()s called properly"
);

done_testing;

