#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;
use Moose ();

my $role = Moose::Meta::Role->create_anon_role(
    attributes => {
        is_worn => {
            is => 'rw',
            isa => 'Bool',
        },
    },
    methods => {
        remove => sub { shift->is_worn(0) },
    },
);

my $class = Moose::Meta::Class->create('MyItem::Armor::Helmet');
$role->apply($class);
# XXX: Moose::Util::apply_all_roles doesn't cope with references yet

my $visored = $class->construct_instance(is_worn => 0);
ok(!$visored->is_worn, "attribute, accessor was consumed");
$visored->is_worn(1);
ok($visored->is_worn, "accessor was consumed");
$visored->remove;
ok(!$visored->is_worn, "method was consumed");

