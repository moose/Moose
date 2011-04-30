#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Moose;

BEGIN {
    eval "use MooseX::InsideOut 0.100 ()";
    plan skip_all => "MooseX::InsideOut is required for this test" if $@;
}

BEGIN {
    require Moose;

    package Foo::Exporter;
    use Moose::Exporter;
    Moose::Exporter->setup_import_methods(also => ['Moose']);

    sub init_meta {
        shift;
        my %options = @_;
        Moose->init_meta(%options);
        Moose::Util::MetaRole::apply_metaroles(
            for             => $options{for_class},
            class_metaroles => {
                instance =>
                    ['MooseX::InsideOut::Role::Meta::Instance'],
            },
        );
        return Class::MOP::class_of($options{for_class});
    }
}

{
    package Foo;

    sub new {
        my $class = shift;
        bless [$_[0]], $class;
    }

    sub foo {
        my $self = shift;
        $self->[0] = shift if @_;
        $self->[0];
    }
}

{
    package Foo::Moose;
    BEGIN { Foo::Exporter->import }
    extends 'Foo';

    has bar => (
        is => 'rw',
        isa => 'Str',
    );

    sub BUILDARGS {
        my $self = shift;
        shift;
        return $self->SUPER::BUILDARGS(@_);
    }
}

{
    package Foo::Moose::Sub;
    use base 'Foo::Moose';
}

with_immutable {
    my $foo = Foo::Moose->new('FOO', bar => 'BAR');
    is($foo->foo, 'FOO', 'base class accessor works');
    is($foo->bar, 'BAR', 'subclass accessor works');
    $foo->foo('OOF');
    $foo->bar('RAB');
    is($foo->foo, 'OOF', 'base class accessor works (setting)');
    is($foo->bar, 'RAB', 'subclass accessor works (setting)');
    my $sub_foo = eval { Foo::Moose::Sub->new(FOO => bar => 'AHOY') };
    is(eval { $sub_foo->bar }, 'AHOY', 'subclass constructor works');
} 'Foo::Moose';

done_testing;
