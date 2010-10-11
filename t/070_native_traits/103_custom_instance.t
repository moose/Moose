#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Moose;

{
    package ValueContainer;
    use Moose;

    has value => (
        is => 'rw',
    );
}

{
    package Foo::Meta::Instance;
    use Moose::Role;

    around get_slot_value => sub {
        my $orig = shift;
        my $self = shift;
        my ($instance, $slot_name) = @_;
        my $value = $self->$orig(@_);
        if ($value->isa('ValueContainer')) {
            $value = $value->value;
        }
        return $value;
    };

    around inline_get_slot_value => sub {
        my $orig = shift;
        my $self = shift;
        my $value = $self->$orig(@_);
        return q[do {] . "\n"
             . q[    my $value = ] . $value . q[;] . "\n"
             . q[    if ($value->isa('ValueContainer')) {] . "\n"
             . q[        $value = $value->value;] . "\n"
             . q[    }] . "\n"
             . q[    $value] . "\n"
             . q[}];
    };

    sub inline_get_is_lvalue { 0 }
}

{
    package Foo;
    use Moose;
    Moose::Util::MetaRole::apply_metaroles(
        for => __PACKAGE__,
        class_metaroles => {
            instance => ['Foo::Meta::Instance'],
        }
    );

    ::lives_ok {
        has foo => (
            traits  => ['String'],
            is      => 'ro',
            isa     => 'Str',
            default => '',
            handles => {
                append_foo => 'append',
            },
        );
    }
}

with_immutable {
    {
        my $foo = Foo->new(foo => 'a');
        is($foo->foo, 'a');
        $foo->append_foo('b');
        is($foo->foo, 'ab');
    }

    {
        my $foo = Foo->new(foo => '');
        $foo->{foo} = ValueContainer->new(value => 'a');
        is($foo->foo, 'a');
        $foo->append_foo('b');
        is($foo->foo, 'ab');
    }
} 'Foo';

done_testing;
