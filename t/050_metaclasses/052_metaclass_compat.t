#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
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
}
{
    package Bar2;
    use Moose;
}
{
    package Baz2;
    use Moose;
    my $meta = __PACKAGE__->meta;
    ::lives_ok { $meta->superclasses('Foo2') } "can set superclasses once";
    ::isa_ok($meta, Foo2->meta->meta->name);
    ::lives_ok { $meta->superclasses('Bar2') } "can still set superclasses";
    ::isa_ok($meta, Bar2->meta->meta->name);
    ::is_deeply([sort map { $_->name } $meta->meta->calculate_all_roles_with_inheritance],
                ['Foo2::Role'],
                "still have the role attached");
    ::ok(!$meta->is_immutable,
       "immutable superclass doesn't make this class immutable");
    ::lives_ok { $meta->make_immutable } "can still make immutable";
}
{
    package Foo3::Role;
    use Moose::Role;
}
{
    package Bar3;
    use Moose -traits => ['Foo3::Role'];
}
{
    package Baz3;
    use Moose -traits => ['Foo3::Role'];
    my $meta = __PACKAGE__->meta;
    ::lives_ok { $meta->superclasses('Foo2') } "can set superclasses once";
    ::isa_ok($meta, Foo2->meta->meta->name);
    ::is_deeply([sort map { $_->name } $meta->meta->calculate_all_roles_with_inheritance],
                ['Foo2::Role', 'Foo3::Role'],
                "reconciled roles correctly");
    ::lives_ok { $meta->superclasses('Bar3') } "can still set superclasses";
    ::isa_ok($meta, Bar3->meta->meta->name);
    ::is_deeply([sort map { $_->name } $meta->meta->calculate_all_roles_with_inheritance],
                ['Foo2::Role', 'Foo3::Role'],
                "roles still the same");
    ::ok(!$meta->is_immutable,
       "immutable superclass doesn't make this class immutable");
    ::lives_ok { $meta->make_immutable } "can still make immutable";
}
{
    package Quux3;
    use Moose;
}
{
    package Quuux3;
    use Moose -traits => ['Foo3::Role'];
    my $meta = __PACKAGE__->meta;
    ::lives_ok { $meta->superclasses('Foo2') } "can set superclasses once";
    ::isa_ok($meta, Foo2->meta->meta->name);
    ::is_deeply([sort map { $_->name } $meta->meta->calculate_all_roles_with_inheritance],
                ['Foo2::Role', 'Foo3::Role'],
                "reconciled roles correctly");
    ::lives_ok { $meta->superclasses('Quux3') } "can still set superclasses";
    ::isa_ok($meta, Quux3->meta->meta->name);
    ::is_deeply([sort map { $_->name } $meta->meta->calculate_all_roles_with_inheritance],
                ['Foo2::Role', 'Foo3::Role'],
                "roles still the same");
    ::ok(!$meta->is_immutable,
       "immutable superclass doesn't make this class immutable");
    ::lives_ok { $meta->make_immutable } "can still make immutable";
}

{
    package Foo4::Role;
    use Moose::Role;
}
{
    package Foo4;
    use Moose -traits => ['Foo4::Role'];
    __PACKAGE__->meta->make_immutable;
}
{
    package Bar4;
    use Moose;
}
{
    package Baz4;
    use Moose;
    my $meta = __PACKAGE__->meta;
    ::lives_ok { $meta->superclasses('Foo4') } "can set superclasses once";
    ::isa_ok($meta, Foo4->meta->_get_mutable_metaclass_name);
    ::lives_ok { $meta->superclasses('Bar4') } "can still set superclasses";
    ::isa_ok($meta, Bar4->meta->meta->name);
    ::is_deeply([sort map { $_->name } $meta->meta->calculate_all_roles_with_inheritance],
                ['Foo4::Role'],
                "still have the role attached");
    ::ok(!$meta->is_immutable,
       "immutable superclass doesn't make this class immutable");
    ::lives_ok { $meta->make_immutable } "can still make immutable";
}
{
    package Foo5::Role;
    use Moose::Role;
}
{
    package Bar5;
    use Moose -traits => ['Foo5::Role'];
}
{
    package Baz5;
    use Moose -traits => ['Foo5::Role'];
    my $meta = __PACKAGE__->meta;
    ::lives_ok { $meta->superclasses('Foo4') } "can set superclasses once";
    ::isa_ok($meta, Foo4->meta->_get_mutable_metaclass_name);
    ::is_deeply([sort map { $_->name } $meta->meta->calculate_all_roles_with_inheritance],
                ['Foo4::Role', 'Foo5::Role'],
                "reconciled roles correctly");
    ::lives_ok { $meta->superclasses('Bar5') } "can still set superclasses";
    ::isa_ok($meta, Bar5->meta->meta->name);
    ::is_deeply([sort map { $_->name } $meta->meta->calculate_all_roles_with_inheritance],
                ['Foo4::Role', 'Foo5::Role'],
                "roles still the same");
    ::ok(!$meta->is_immutable,
       "immutable superclass doesn't make this class immutable");
    ::lives_ok { $meta->make_immutable } "can still make immutable";
}
{
    package Quux5;
    use Moose;
}
{
    package Quuux5;
    use Moose -traits => ['Foo5::Role'];
    my $meta = __PACKAGE__->meta;
    ::lives_ok { $meta->superclasses('Foo4') } "can set superclasses once";
    ::isa_ok($meta, Foo4->meta->_get_mutable_metaclass_name);
    ::is_deeply([sort map { $_->name } $meta->meta->calculate_all_roles_with_inheritance],
                ['Foo4::Role', 'Foo5::Role'],
                "reconciled roles correctly");
    ::lives_ok { $meta->superclasses('Quux5') } "can still set superclasses";
    ::isa_ok($meta, Quux5->meta->meta->name);
    ::is_deeply([sort map { $_->name } $meta->meta->calculate_all_roles_with_inheritance],
                ['Foo4::Role', 'Foo5::Role'],
                "roles still the same");
    ::ok(!$meta->is_immutable,
       "immutable superclass doesn't make this class immutable");
    ::lives_ok { $meta->make_immutable } "can still make immutable";
}

{
    package Foo5::Meta::Role;
    use Moose::Role;
}
{
    package Foo5::SuperClass::WithMetaRole;
    use Moose -traits =>'Foo5::Meta::Role';
}
{
    package Foo5::SuperClass::After::Attribute;
    use Moose;
}
{
    package Foo5;
    use Moose;
    my @superclasses = ('Foo5::SuperClass::WithMetaRole');
    extends @superclasses;

    has an_attribute_generating_methods => ( is => 'ro' );

    push(@superclasses, 'Foo5::SuperClass::After::Attribute');

    ::lives_ok {
        extends @superclasses;
    } 'MI extends after_generated_methods with metaclass roles';
    ::lives_ok {
        extends reverse @superclasses;
    }
    'MI extends after_generated_methods with metaclass roles (reverse)';
}

{
    package Foo6::Meta::Role;
    use Moose::Role;
}
{
    package Foo6::SuperClass::WithMetaRole;
    use Moose -traits =>'Foo6::Meta::Role';
}
{
    package Foo6::Meta::OtherRole;
    use Moose::Role;
}
{
    package Foo6::SuperClass::After::Attribute;
    use Moose -traits =>'Foo6::Meta::OtherRole';
}
{
    package Foo6;
    use Moose;
    my @superclasses = ('Foo6::SuperClass::WithMetaRole');
    extends @superclasses;

    has an_attribute_generating_methods => ( is => 'ro' );

    push(@superclasses, 'Foo6::SuperClass::After::Attribute');

    ::throws_ok {
        extends @superclasses;
    } qr/compat.*pristine/,
    'unsafe MI extends after_generated_methods with metaclass roles';
    ::throws_ok {
        extends reverse @superclasses;
    } qr/compat.*pristine/,
    'unsafe MI extends after_generated_methods with metaclass roles (reverse)';
}

{
    package Foo7::Meta::Trait;
    use Moose::Role;
}

{
    package Foo7;
    use Moose -traits => ['Foo7::Meta::Trait'];
}

{
    package Bar7;
    # in an external file
    use Moose -traits => ['Bar7::Meta::Trait'];
    ::lives_ok { extends 'Foo7' } "role reconciliation works";
}

{
    package Bar72;
    # in an external file
    use Moose -traits => ['Bar7::Meta::Trait2'];
    ::lives_ok { extends 'Foo7' } "role reconciliation works";
}

done_testing;
