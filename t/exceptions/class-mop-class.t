#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Try::Tiny;

use Moose::Util::TypeConstraints;
use Class::MOP::Class;

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

done_testing;
