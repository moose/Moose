#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

our $called = 0;
{
    package Foo::Trait::Constructor;
    use Moose::Role;

    around _generate_BUILDALL => sub {
        my $orig = shift;
        my $self = shift;
        return $self->$orig(@_) . '$::called++;';
    }
}

{
    package Foo;
    use Moose;
    Moose::Util::MetaRole::apply_metaroles(
        for => __PACKAGE__,
        class_metaroles => {
            constructor => ['Foo::Trait::Constructor'],
        }
    );
}

Foo->new;
is($called, 0, "no calls before inlining");
Foo->meta->make_immutable;

Foo->new;
is($called, 1, "inlined constructor has trait modifications");

ok(Foo->meta->constructor_class->meta->does_role('Foo::Trait::Constructor'),
   "class has correct constructor traits");

{
    package Foo::Sub;
    use Moose;
    extends 'Foo';
}

$called = 0;

Foo::Sub->new;
is($called, 0, "no calls before inlining");

Foo::Sub->meta->make_immutable;

Foo::Sub->new;
is($called, 1, "inherits constructor trait properly");

ok(Foo::Sub->meta->constructor_class->meta->can('does_role')
&& Foo::Sub->meta->constructor_class->meta->does_role('Foo::Trait::Constructor'),
   "subclass inherits constructor traits");

{
    package Foo2::Role;
    use Moose::Role;
}
{
    package Foo2;
    use Moose -traits => ['Foo2::Role'];
    __PACKAGE__->meta->make_immutable;
}
{
    package Bar2;
    use Moose;
}
{
    package Baz2;
    use Moose;
    my $meta = __PACKAGE__->meta;
    $meta->superclasses('Foo2');
    { our $TODO; local $TODO = "need to handle immutability better";
    ::lives_ok { $meta->superclasses('Bar2') };
    }
}

done_testing;
