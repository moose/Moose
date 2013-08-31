#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose();

{
    my $exception =  exception {
	my $class = Class::MOP::Class::initialize;
    };

    like(
        $exception,
        qr/You must pass a package name and it cannot be blessed/,
        "no package name given to initialize");

    isa_ok(
        $exception,
        "Moose::Exception::InitializeTakesUnBlessedPackageName",
        "no package name given to initialize");
}

{
    my $exception =  exception {
	my $class = Class::MOP::Class::create("Foo" => ( superclasses => ('foo') ));
    };

    like(
        $exception,
        qr/You must pass an ARRAY ref of superclasses/,
        "an Array is of superclasses is passed");

    isa_ok(
        $exception,
        "Moose::Exception::CreateMOPClassTakesArrayRefOfSuperclasses",
        "an Array is of superclasses is passed");

    is(
	$exception->class,
	'Foo',
        "an Array is of superclasses is passed");
}


{
    my $exception =  exception {
	my $class = Class::MOP::Class::create("Foo" => ( attributes => ('foo') ));
    };

    like(
        $exception,
        qr/You must pass an ARRAY ref of attributes/,
        "an Array is of attributes is passed");

    isa_ok(
        $exception,
        "Moose::Exception::CreateMOPClassTakesArrayRefOfAttributes",
        "an Array is of attributes is passed");

    is(
	$exception->class,
	'Foo',
        "an Array is of attributes is passed");
}

{
    my $exception =  exception {
	my $class = Class::MOP::Class::create("Foo" => ( methods => ('foo') ) );
    };

    like(
        $exception,
        qr/You must pass an HASH ref of methods/,
        "a Hash is of methods is passed");

    isa_ok(
        $exception,
        "Moose::Exception::CreateMOPClassTakesHashRefOfMethods",
        "a Hash is of methods is passed");

    is(
	$exception->class,
	'Foo',
        "a Hash is of methods is passed");
}

{
    my $exception =  exception {
        my $class = Class::MOP::Class->create("Foo");
        $class->find_method_by_name;
    };

    like(
        $exception,
        qr/You must define a method name to find/,
        "no method name given to find_method_by_name");

    isa_ok(
        $exception,
        "Moose::Exception::MethodNameNotGiven",
        "no method name given to find_method_by_name");

    is(
	$exception->class->name,
	'Foo',
        "no method name given to find_method_by_name");
}

{
    my $exception =  exception {
        my $class = Class::MOP::Class->create("Foo");
        $class->find_all_methods_by_name;
    };

    like(
        $exception,
        qr/You must define a method name to find/,
        "no method name given to find_all_methods_by_name");

    isa_ok(
        $exception,
        "Moose::Exception::MethodNameNotGiven",
        "no method name given to find_all_methods_by_name");

    is(
	$exception->class->name,
	'Foo',
        "no method name given to find_all_methods_by_name");
}

{
    my $exception =  exception {
        my $class = Class::MOP::Class->create("Foo");
        $class->find_next_method_by_name;
    };

    like(
        $exception,
        qr/You must define a method name to find/,
        "no method name given to find_next_method_by_name");

    isa_ok(
        $exception,
        "Moose::Exception::MethodNameNotGiven",
        "no method name given to find_next_method_by_name");

    is(
	$exception->class->name,
	'Foo',
        "no method name given to find_next_method_by_name");
}

{
    my $class = Class::MOP::Class->create("Foo");
    my $foo = "foo";
    my $exception =  exception {
	$class->clone_object( $foo );
    };

    like(
        $exception,
        qr/\QYou must pass an instance of the metaclass (Foo), not ($foo)/,
	"clone_object expects an instance of the metaclass");

    isa_ok(
        $exception,
        "Moose::Exception::CloneObjectExpectsAnInstanceOfMetaclass",
	"clone_object expects an instance of the metaclass");

    is(
	$exception->class->name,
	'Foo',
	"clone_object expects an instance of the metaclass");

   is(
	$exception->instance,
	'foo',
	"clone_object expects an instance of the metaclass");
}

{
    {
	package Foo;
	use Moose;
    }
    {
	package Foo2;
	use Moose;
    }
    my $foo2 = Foo2->new;
    my $exception =  exception {
	Foo->meta->rebless_instance( $foo2 );
    };

    like(
        $exception,
        qr/\QYou may rebless only into a subclass of (Foo2), of which (Foo) isn't./,
	"you can rebless only into subclass");

    isa_ok(
        $exception,
        "Moose::Exception::CanReblessOnlyIntoASubclass",
	"you can rebless only into subclass");

    is(
	$exception->class->name,
	'Foo',
	"you can rebless only into subclass");

   is(
	$exception->instance,
	$foo2,
	"you can rebless only into subclass");
}

{
    {
	package Foo;
	use Moose;
    }
    {
	package Foo2;
	use Moose;
    }
    my $foo = Foo->new;
    my $exception =  exception {
	Foo2->meta->rebless_instance_back( $foo );
    };

    like(
        $exception,
        qr/\QYou may rebless only into a superclass of (Foo), of which (Foo2) isn't./,
	"you can rebless only into superclass");

    isa_ok(
        $exception,
        "Moose::Exception::CanReblessOnlyIntoASuperclass",
	"you can rebless only into superclass");

    is(
	$exception->instance,
	$foo,
	"you can rebless only into superclass");

   is(
	$exception->class->name,
	"Foo2",
	"you can rebless only into superclass");
}

{
    {
	package Foo;
	use Moose;
    }
    my $exception =  exception {
	Foo->meta->add_before_method_modifier;
    };

    like(
        $exception,
        qr/You must pass in a method name/,
	"no method name passed to method modifier");

    isa_ok(
        $exception,
        "Moose::Exception::MethodModifierNeedsMethodName",
	"no method name passed to method modifier");

    is(
	$exception->class->name,
	"Foo",
	"no method name passed to method modifier");
}

{
    {
	package Foo;
	use Moose;
    }
    my $exception =  exception {
	Foo->meta->add_after_method_modifier;
    };

    like(
        $exception,
        qr/You must pass in a method name/,
	"no method name passed to method modifier");

    isa_ok(
        $exception,
        "Moose::Exception::MethodModifierNeedsMethodName",
	"no method name passed to method modifier");

    is(
	$exception->class->name,
	"Foo",
	"no method name passed to method modifier");
}

{
    {
	package Foo;
	use Moose;
    }
    my $exception =  exception {
	Foo->meta->add_around_method_modifier;
    };

    like(
        $exception,
        qr/You must pass in a method name/,
	"no method name passed to method modifier");

    isa_ok(
        $exception,
        "Moose::Exception::MethodModifierNeedsMethodName",
	"no method name passed to method modifier");

    is(
	$exception->class->name,
	"Foo",
	"no method name passed to method modifier");
}

{
    my $exception =  exception {
	my $class = Class::MOP::Class->_construct_class_instance;
    };

    like(
        $exception,
        qr/You must pass a package name/,
        "no package name given to _construct_class_instance");

    isa_ok(
        $exception,
        "Moose::Exception::ConstructClassInstanceTakesPackageName",
        "no package name given to _construct_class_instance");
}

{
    my $class = Class::MOP::Class->create("Foo");
    my $exception =  exception {
	$class->add_before_method_modifier("foo");
    };

    like(
        $exception,
        qr/The method 'foo' was not found in the inheritance hierarchy for Foo/,
	'method "foo" is not defined in class "Foo"');

    isa_ok(
        $exception,
        "Moose::Exception::MethodNameNotFoundInInheritanceHierarchy",
	'method "foo" is not defined in class "Foo"');

    is(
	$exception->class->name,
	'Foo',
	'method "foo" is not defined in class "Foo"');

   is(
	$exception->method_name,
	'foo',
	'method "foo" is not defined in class "Foo"');
}

{
    {
	package Bar;
	use Moose;
    }
    my $bar = Bar->new;
    my $class = Class::MOP::Class->create("Foo");
    my $exception =  exception {
	$class->new_object( ( __INSTANCE__ => $bar ) );
    };

    like(
        $exception,
        qr/\QObjects passed as the __INSTANCE__ parameter must already be blessed into the correct class, but $bar is not a Foo/,
	"__INSTANCE__ is not blessed correctly");

    isa_ok(
        $exception,
        "Moose::Exception::InstanceBlessedIntoWrongClass",
	"__INSTANCE__ is not blessed correctly");

    is(
	$exception->class->name,
	'Foo',
	"__INSTANCE__ is not blessed correctly");

   is(
	$exception->instance,
	$bar,
	"__INSTANCE__ is not blessed correctly");
}

{
    my $class = Class::MOP::Class->create("Foo");
    my $array = [1,2,3];
    my $exception =  exception {
	$class->new_object( ( __INSTANCE__ => $array ) );
    };

    like(
        $exception,
        qr/\QThe __INSTANCE__ parameter must be a blessed reference, not $array/,
	"__INSTANCE__ is not a blessed reference");

    isa_ok(
        $exception,
        "Moose::Exception::InstanceMustBeABlessedReference",
	"__INSTANCE__ is not a blessed reference");

    is(
	$exception->class->name,
	'Foo',
	"__INSTANCE__ is not a blessed reference");

   is(
	$exception->instance,
	$array,
	"__INSTANCE__ is not a blessed reference");
}

{
    my $array = [1, 2, 3];
    my $class = Class::MOP::Class->create("Foo");
    my $exception =  exception {
	$class->_clone_instance($array);
    };

    like(
        $exception,
        qr/\QYou can only clone instances, ($array) is not a blessed instance/,
	"array reference was passed to _clone_instance instead of a blessed instance");

    isa_ok(
        $exception,
        "Moose::Exception::OnlyInstancesCanBeCloned",
	"array reference was passed to _clone_instance instead of a blessed instance");

    is(
	$exception->class->name,
	"Foo",
	"array reference was passed to _clone_instance instead of a blessed instance");

    is(
	$exception->instance,
	$array,
	"array reference was passed to _clone_instance instead of a blessed instance");
}

{
    {
        package My::Role;
        use Moose::Role;
    }

    my $exception = exception {
        Class::MOP::Class->create("My::Class", superclasses => ["My::Role"]);
    };

    like(
        $exception,
        qr/\QThe metaclass of My::Class (Class::MOP::Class) is not compatible with the metaclass of its superclass, My::Role (Moose::Meta::Role) /,
        "Trying to inherit a Role");

    isa_ok(
        $exception,
        "Moose::Exception::IncompatibleMetaclassOfSuperclass",
        "Trying to inherit a Role");

    is(
        $exception->class->name,
        "My::Class",
        "Trying to inherit a Role");

    is(
        $exception->superclass_name,
        "My::Role",
        "Trying to inherit a Role");

    is(
        $exception->superclass_meta_type,
        "Moose::Meta::Role",
        "Trying to inherit a Role");
}

{
    {
        package Super::Class;
        use Moose;
    }

    my $class = Class::MOP::Class->create("TestClass", superclasses => ["Super::Class"]);
    $class->immutable_trait(undef);
    my $exception = exception {
        $class->make_immutable( immutable_trait => '');
    };

    like(
        $exception,
        qr/\Qno immutable trait specified for $class/,
        "immutable_trait set to undef");

    isa_ok(
        $exception,
        "Moose::Exception::NoImmutableTraitSpecifiedForClass",
        "immutable_trait set to undef");

    is(
        $exception->class->name,
        "TestClass",
        "immutable_trait set to undef");
}

{
    my $exception = exception {
        package NoDestructorClass;
        use Moose;

        __PACKAGE__->meta->make_immutable( destructor_class => undef, inline_destructor => 1 );
    };

    like(
        $exception,
        qr/The 'inline_destructor' option is present, but no destructor class was specified/,
        "destructor_class is set to undef");

    isa_ok(
        $exception,
        "Moose::Exception::NoDestructorClassSpecified",
        "destructor_class is set to undef");

    is(
        $exception->class->name,
        "NoDestructorClass",
        "destructor_class is set to undef");
}

done_testing;
