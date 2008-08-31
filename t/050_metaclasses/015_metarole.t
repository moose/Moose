#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 59;

use Moose::Util::MetaRole;


{
    package My::Meta::Class;
    use Moose;
    extends 'Moose::Meta::Class';
}

{
    package My::Meta::Attribute;
    use Moose;
    extends 'Moose::Meta::Attribute';
}

{
    package My::Meta::Method;
    use Moose;
    extends 'Moose::Meta::Method';
}

{
    package My::Meta::Instance;
    use Moose;
    extends 'Moose::Meta::Instance';
}

{
    package My::Meta::MethodConstructor;
    use Moose;
    extends 'Moose::Meta::Method::Constructor';
}

{
    package My::Meta::MethodDestructor;
    use Moose;
    extends 'Moose::Meta::Method::Destructor';
}

{
    package Role::Foo;
    use Moose::Role;
    has 'foo' => ( is => 'ro', default => 10 );
}

{
    package My::Class;

    use Moose;
}

{
    Moose::Util::MetaRole::apply_metaclass_roles(
        for_class       => 'My::Class',
        metaclass_roles => ['Role::Foo'],
    );

    ok( My::Class->meta()->meta()->does_role('Role::Foo'),
        'apply Role::Foo to My::Class->meta()' );
    is( My::Class->meta()->foo(), 10,
        '... and call foo() on that meta object' );
}

{
    Moose::Util::MetaRole::apply_metaclass_roles(
        for_class                 => 'My::Class',
        attribute_metaclass_roles => ['Role::Foo'],
    );

    ok( My::Class->meta()->attribute_metaclass()->meta()->does_role('Role::Foo'),
        q{apply Role::Foo to My::Class->meta()'s attribute metaclass} );
    ok( My::Class->meta()->meta()->does_role('Role::Foo'),
        '... My::Class->meta() still does Role::Foo' );

    My::Class->meta()->add_attribute( 'size', is => 'ro' );
    is( My::Class->meta()->get_attribute('size')->foo(), 10,
        '... call foo() on an attribute metaclass object' );
}

{
    Moose::Util::MetaRole::apply_metaclass_roles(
        for_class              => 'My::Class',
        method_metaclass_roles => ['Role::Foo'],
    );

    ok( My::Class->meta()->method_metaclass()->meta()->does_role('Role::Foo'),
        q{apply Role::Foo to My::Class->meta()'s method metaclass} );
    ok( My::Class->meta()->meta()->does_role('Role::Foo'),
        '... My::Class->meta() still does Role::Foo' );
    ok( My::Class->meta()->attribute_metaclass()->meta()->does_role('Role::Foo'),
        q{... My::Class->meta()'s attribute metaclass still does Role::Foo} );

    My::Class->meta()->add_method( 'bar' => sub { 'bar' } );
    is( My::Class->meta()->get_method('bar')->foo(), 10,
        '... call foo() on a method metaclass object' );
}

{
    Moose::Util::MetaRole::apply_metaclass_roles(
        for_class              => 'My::Class',
        instance_metaclass_roles => ['Role::Foo'],
    );

    ok( My::Class->meta()->instance_metaclass()->meta()->does_role('Role::Foo'),
        q{apply Role::Foo to My::Class->meta()'s instance metaclass} );
    ok( My::Class->meta()->meta()->does_role('Role::Foo'),
        '... My::Class->meta() still does Role::Foo' );
    ok( My::Class->meta()->attribute_metaclass()->meta()->does_role('Role::Foo'),
        q{... My::Class->meta()'s attribute metaclass still does Role::Foo} );
    ok( My::Class->meta()->method_metaclass()->meta()->does_role('Role::Foo'),
        q{... My::Class->meta()'s method metaclass still does Role::Foo} );

    is( My::Class->meta()->get_meta_instance()->foo(), 10,
        '... call foo() on an instance metaclass object' );
}

{
    Moose::Util::MetaRole::apply_metaclass_roles(
        for_class               => 'My::Class',
        constructor_class_roles => ['Role::Foo'],
    );

    ok( My::Class->meta()->constructor_class()->meta()->does_role('Role::Foo'),
        q{apply Role::Foo to My::Class->meta()'s constructor class} );
    ok( My::Class->meta()->meta()->does_role('Role::Foo'),
        '... My::Class->meta() still does Role::Foo' );
    ok( My::Class->meta()->attribute_metaclass()->meta()->does_role('Role::Foo'),
        q{... My::Class->meta()'s attribute metaclass still does Role::Foo} );
    ok( My::Class->meta()->method_metaclass()->meta()->does_role('Role::Foo'),
        q{... My::Class->meta()'s method metaclass still does Role::Foo} );
    ok( My::Class->meta()->instance_metaclass()->meta()->does_role('Role::Foo'),
        q{... My::Class->meta()'s instance metaclass still does Role::Foo} );

    # Actually instantiating the constructor class is too freaking hard!
    ok( My::Class->meta()->constructor_class()->can('foo'),
        '... constructor class has a foo method' );
}

{
    Moose::Util::MetaRole::apply_metaclass_roles(
        for_class              => 'My::Class',
        destructor_class_roles => ['Role::Foo'],
    );

    ok( My::Class->meta()->destructor_class()->meta()->does_role('Role::Foo'),
        q{apply Role::Foo to My::Class->meta()'s destructor class} );
    ok( My::Class->meta()->meta()->does_role('Role::Foo'),
        '... My::Class->meta() still does Role::Foo' );
    ok( My::Class->meta()->attribute_metaclass()->meta()->does_role('Role::Foo'),
        q{... My::Class->meta()'s attribute metaclass still does Role::Foo} );
    ok( My::Class->meta()->method_metaclass()->meta()->does_role('Role::Foo'),
        q{... My::Class->meta()'s method metaclass still does Role::Foo} );
    ok( My::Class->meta()->instance_metaclass()->meta()->does_role('Role::Foo'),
        q{... My::Class->meta()'s instance metaclass still does Role::Foo} );
    ok( My::Class->meta()->constructor_class()->meta()->does_role('Role::Foo'),
        q{... My::Class->meta()'s constructor class still does Role::Foo} );

    # same problem as the constructor class
    ok( My::Class->meta()->destructor_class()->can('foo'),
        '... destructor class has a foo method' );
}

{
    Moose::Util::MetaRole::apply_base_class_roles(
        for_class => 'My::Class',
        roles     => ['Role::Foo'],
    );

    ok( My::Class->meta()->does_role('Role::Foo'),
        'apply Role::Foo to My::Class base class' );
    is( My::Class->new()->foo(), 10,
        '... call foo() on a My::Class object' );
}

{
    package My::Class2;

    use Moose;
}

{
    Moose::Util::MetaRole::apply_metaclass_roles(
        for_class                 => 'My::Class2',
        metaclass_roles           => ['Role::Foo'],
        attribute_metaclass_roles => ['Role::Foo'],
        method_metaclass_roles    => ['Role::Foo'],
        instance_metaclass_roles  => ['Role::Foo'],
        constructor_class_roles   => ['Role::Foo'],
        destructor_class_roles    => ['Role::Foo'],
    );

    ok( My::Class2->meta()->meta()->does_role('Role::Foo'),
        'apply Role::Foo to My::Class2->meta()' );
    is( My::Class2->meta()->foo(), 10,
        '... and call foo() on that meta object' );
    ok( My::Class2->meta()->attribute_metaclass()->meta()->does_role('Role::Foo'),
        q{apply Role::Foo to My::Class2->meta()'s attribute metaclass} );
    My::Class2->meta()->add_attribute( 'size', is => 'ro' );

    is( My::Class2->meta()->get_attribute('size')->foo(), 10,
        '... call foo() on an attribute metaclass object' );

    ok( My::Class2->meta()->method_metaclass()->meta()->does_role('Role::Foo'),
        q{apply Role::Foo to My::Class2->meta()'s method metaclass} );

    My::Class2->meta()->add_method( 'bar' => sub { 'bar' } );
    is( My::Class2->meta()->get_method('bar')->foo(), 10,
        '... call foo() on a method metaclass object' );

    ok( My::Class2->meta()->instance_metaclass()->meta()->does_role('Role::Foo'),
        q{apply Role::Foo to My::Class2->meta()'s instance metaclass} );
    is( My::Class2->meta()->get_meta_instance()->foo(), 10,
        '... call foo() on an instance metaclass object' );

    ok( My::Class2->meta()->constructor_class()->meta()->does_role('Role::Foo'),
        q{apply Role::Foo to My::Class2->meta()'s constructor class} );
    ok( My::Class2->meta()->constructor_class()->can('foo'),
        '... constructor class has a foo method' );

    ok( My::Class2->meta()->destructor_class()->meta()->does_role('Role::Foo'),
        q{apply Role::Foo to My::Class2->meta()'s destructor class} );
    ok( My::Class2->meta()->destructor_class()->can('foo'),
        '... destructor class has a foo method' );
}


{
    package My::Meta;

    use Moose::Exporter;
    Moose::Exporter->setup_import_methods( also => 'Moose' );

    sub init_meta {
        shift;
        my %p = @_;

        Moose->init_meta( %p, metaclass => 'My::Meta::Class' );
    }
}

{
    package My::Class3;

    My::Meta->import();
}


{
    Moose::Util::MetaRole::apply_metaclass_roles(
        for_class                 => 'My::Class3',
        metaclass_roles           => ['Role::Foo'],
    );

    ok( My::Class3->meta()->meta()->does_role('Role::Foo'),
        'apply Role::Foo to My::Class3->meta()' );
    is( My::Class3->meta()->foo(), 10,
        '... and call foo() on that meta object' );
    ok( ( grep { $_ eq 'My::Meta::Class' } My::Class3->meta()->meta()->superclasses() ),
        'apply_metaclass_roles() does not interfere with metaclass set via Moose->init_meta()' );
}

{
    package Role::Bar;
    use Moose::Role;
    has 'bar' => ( is => 'ro', default => 200 );
}

{
    package My::Class4;
    use Moose;
}

{
    Moose::Util::MetaRole::apply_metaclass_roles(
        for_class                 => 'My::Class4',
        metaclass_roles           => ['Role::Foo'],
    );

    ok( My::Class4->meta()->meta()->does_role('Role::Foo'),
        'apply Role::Foo to My::Class4->meta()' );

    Moose::Util::MetaRole::apply_metaclass_roles(
        for_class                 => 'My::Class4',
        metaclass_roles           => ['Role::Bar'],
    );

    ok( My::Class4->meta()->meta()->does_role('Role::Bar'),
        'apply Role::Bar to My::Class4->meta()' );
    ok( My::Class4->meta()->meta()->does_role('Role::Foo'),
        '... and My::Class4->meta() still does Role::Foo' );
}

{
    package My::Class5;
    use Moose;

    extends 'My::Class';
}

{
    ok( My::Class5->meta()->meta()->does_role('Role::Foo'),
        q{My::Class55->meta()'s does Role::Foo because it extends My::Class} );
    ok( My::Class5->meta()->attribute_metaclass()->meta()->does_role('Role::Foo'),
        q{My::Class5->meta()'s attribute metaclass also does Role::Foo} );
    ok( My::Class5->meta()->method_metaclass()->meta()->does_role('Role::Foo'),
        q{My::Class5->meta()'s method metaclass also does Role::Foo} );
    ok( My::Class5->meta()->instance_metaclass()->meta()->does_role('Role::Foo'),
        q{My::Class5->meta()'s instance metaclass also does Role::Foo} );
    ok( My::Class5->meta()->constructor_class()->meta()->does_role('Role::Foo'),
        q{My::Class5->meta()'s constructor class also does Role::Foo} );
    ok( My::Class5->meta()->destructor_class()->meta()->does_role('Role::Foo'),
        q{My::Class5->meta()'s destructor class also does Role::Foo} );
}

{
    Moose::Util::MetaRole::apply_metaclass_roles(
        for_class       => 'My::Class5',
        metaclass_roles => ['Role::Bar'],
    );

    ok( My::Class5->meta()->meta()->does_role('Role::Bar'),
        q{apply Role::Bar My::Class5->meta()} );
    ok( My::Class5->meta()->meta()->does_role('Role::Foo'),
        q{... and My::Class5->meta() still does Role::Foo} );
}

SKIP:
{
    skip
        'These tests will fail until Moose::Meta::Class->_fix_metaclass_incompatibility is much smarter.',
        2;

{
    package My::Class6;
    use Moose;

    Moose::Util::MetaRole::apply_metaclass_roles(
        for_class       => 'My::Class6',
        metaclass_roles => ['Role::Bar'],
    );

    extends 'My::Class';
}

{
    ok( My::Class6->meta()->meta()->does_role('Role::Bar'),
        q{apply Role::Bar My::Class6->meta() before extends} );
    ok( My::Class6->meta()->meta()->does_role('Role::Foo'),
        q{... and My::Class6->meta() does Role::Foo because it extends My::Class} );
}
}

# This is the hack needed to work around the
# _fix_metaclass_incompatibility problem. You must call extends()
# (which in turn calls _fix_metaclass_imcompatibility) _before_ you
# apply more extensions in the subclass.
{
    package My::Class7;
    use Moose;

    # In real usage this would go in a BEGIN block so it happened
    # before apply_metaclass_roles was called by an extension.
    extends 'My::Class';

    Moose::Util::MetaRole::apply_metaclass_roles(
        for_class       => 'My::Class7',
        metaclass_roles => ['Role::Bar'],
    );
}

{
    ok( My::Class7->meta()->meta()->does_role('Role::Bar'),
        q{apply Role::Bar My::Class7->meta() before extends} );
    ok( My::Class7->meta()->meta()->does_role('Role::Foo'),
        q{... and My::Class7->meta() does Role::Foo because it extends My::Class} );
}
