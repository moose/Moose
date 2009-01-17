#!/usr/bin/perl
use strict;
use warnings;

BEGIN {
    # attribute metaclass for specifying with 'has'
    package Foo::Meta::Attribute;
    use Moose;
    extends 'Moose::Meta::Attribute';

    around _process_options => sub {
        my $orig = shift;
        my ($class, $name, $opts) = @_;
        my $default = delete $opts->{default};
        $opts->{default} = sub { $default->() . "1" };
        $class->$orig($name, $opts);
    };

    # trait for specifying with has
    package Foo::Meta::Trait;
    use Moose::Role;

    around _process_options => sub {
        my $orig = shift;
        my ($class, $name, $opts) = @_;
        my $default = delete $opts->{default};
        $opts->{default} = sub { $default->() . "2" };
        $class->$orig($name, $opts);
    };

    # attribute metaclass role for specifying with MetaRole
    package Foo::Meta::Role::Attribute;
    use Moose::Role;

    around _process_options => sub {
        my $orig = shift;
        my ($class, $name, $opts) = @_;
        my $default = delete $opts->{default};
        $opts->{default} = sub { "3" . $default->() };
        $class->$orig($name, $opts);
    };

    package Foose;
    use Moose ();
    use Moose::Exporter;
    use Moose::Util::MetaRole;

    Moose::Exporter->setup_import_methods(also => ['Moose']);

    sub init_meta {
        shift;
        my %options = @_;
        Moose->init_meta(%options);
        Moose::Util::MetaRole::apply_metaclass_roles(
            for_class                 => $options{for_class},
            attribute_metaclass_roles => ['Foo::Meta::Role::Attribute'],
        );
        return $options{for_class}->meta;
    }
}

# class that uses both
{
    package Foo;
    BEGIN { Foose->import }

    has bar => (
        is  => 'ro',
        isa => 'Str',
        lazy => 1,
        default => sub { 'BAR' },
    );

    has baz => (
        metaclass => 'Foo::Meta::Attribute',
        is  => 'ro',
        isa => 'Str',
        lazy => 1,
        default => sub { 'BAZ' },
    );

    has quux => (
        traits => ['Foo::Meta::Trait'],
        is  => 'ro',
        isa => 'Str',
        lazy => 1,
        default => sub { 'QUUX' },
    );
}

use Test::More tests => 8;
my $foo = Foo->new;
is($foo->bar, '3BAR', 'Attribute meta-role applied by exporter');
ok($foo->meta->get_attribute('bar')->meta->does_role('Foo::Meta::Role::Attribute'), 'normal attribute does the meta-role');

TODO: {
    local $TODO = 'metaclass on attribute currently overrides attr metarole';
    is($foo->baz, '3BAZ1', 'Attribute meta role from exporter + metaclass on attribute');
    ok($foo->meta->get_attribute('baz')->meta->does_role('Foo::Meta::Role::Attribute'), 'attribute using metaclass does the meta-role');
};
ok($foo->meta->get_attribute('baz')->isa('Foo::Meta::Attribute'), 'attribute using a metaclass isa the metaclass');

is($foo->quux, '3QUUX2', 'Attribute meta-role + trait');
ok($foo->meta->get_attribute('quux')->meta->does_role('Foo::Meta::Role::Attribute'), 'attribute using a trait does the meta-role');
ok($foo->meta->get_attribute('quux')->meta->does_role('Foo::Meta::Trait'), 'attribute using a trait does the trait');
