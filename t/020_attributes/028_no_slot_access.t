#!/usr/bin/perl

use strict;
use warnings;

{
    package SomeAwesomeDB;

    sub new_row { }
    sub read    { }
    sub write   { }
}

{
    package MooseX::SomeAwesomeDBFields;

    # implementation of methods not called in the example deliberately
    # omitted

    use Moose::Role;

    sub inline_create_instance {
        my ( $self, $classvar ) = @_;

        "bless SomeAwesomeDB::new_row(), $classvar";
    }

    sub inline_get_slot_value {
        my ( $self, $invar, $slot ) = @_;

        "SomeAwesomeDB::read($invar, \"$slot\")";
    }

    sub inline_set_slot_value {
        my ( $self, $invar, $slot, $valexp ) = @_;

        "SomeAwesomeDB::write($invar, \"$slot\", $valexp)";
    }

    sub inline_is_slot_initialized {
        my ( $self, $invar, $slot ) = @_;

        "1";
    }

    sub inline_initialize_slot {
        my ( $self, $invar, $slot ) = @_;

        "";
    }

    sub inline_slot_access {
        die "inline_slot_access should not have been used";
    }
}

{
    package Toy;

    use Moose;
    use Moose::Util::MetaRole;

    use Test::More;
    use Test::Exception;

    Moose::Util::MetaRole::apply_metaroles(
        for             => __PACKAGE__,
        class_metaroles => { instance => ['MooseX::SomeAwesomeDBFields'] },
    );

    lives_ok {
        has lazy_attr => (
            is      => 'ro',
            isa     => 'Bool',
            lazy    => 1,
            default => sub {0},
        );
    }
    "Adding lazy accessor does not use inline_slot_access";

    lives_ok {
        has rw_attr => (
            is => 'rw',
        );
    }
    "Adding read-write accessor does not use inline_slot_access";

    lives_ok { __PACKAGE__->meta->make_immutable; }
    "Inling constructor does not use inline_slot_access";

    done_testing;
}
