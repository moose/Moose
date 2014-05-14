
use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose();

use Moose::Util 'find_meta';

{
    my $exception = exception {
        package Bar;
        use Moose::Role;
        extends 'Foo';
    };

    like(
        $exception,
        qr/\QRoles do not support 'extends' (you can use 'with' to specialize a role)/,
        "Roles do not support extends");

    isa_ok(
        $exception,
        "Moose::Exception::RolesDoNotSupportExtends",
        "Roles do not support extends");
}

{
    my $exception = exception {
        package Bar;
        use Moose::Role;
        requires;
    };

    like(
        $exception,
        qr/Must specify at least one method/,
        "requires expects atleast one method name");

    isa_ok(
        $exception,
        "Moose::Exception::MustSpecifyAtleastOneMethod",
        "requires expects atleast one method name");

    is(
        $exception->role_name,
        'Bar',
        'requires expects atleast one method name');
}

{
    my $exception = exception {
        package Bar;
        use Moose::Role;
        excludes;
    };

    like(
        $exception,
        qr/Must specify at least one role/,
        "excludes expects atleast one role name");

    isa_ok(
        $exception,
        "Moose::Exception::MustSpecifyAtleastOneRole",
        "excludes expects atleast one role name");

    is(
        $exception->role_name,
        'Bar',
        'excludes expects atleast one role name');
}

{
    my $exception = exception {
        package Bar;
        use Moose::Role;
        inner;
    };

    like(
        $exception,
        qr/Roles cannot support 'inner'/,
        "Roles do not support 'inner'");

    isa_ok(
        $exception,
        "Moose::Exception::RolesDoNotSupportInner",
        "Roles do not support 'inner'");
}

{
    my $exception = exception {
        package Bar;
        use Moose::Role;
        augment 'foo' => sub {};
    };

    like(
        $exception,
        qr/Roles cannot support 'augment'/,
        "Roles do not support 'augment'");

    isa_ok(
        $exception,
        "Moose::Exception::RolesDoNotSupportAugment",
        "Roles do not support 'augment'");
}

{
    my $exception = exception {
        {
            package Foo1;
            use Moose::Role;
            has 'bar' => (
                is =>
            );
        }
    };

    like(
        $exception,
        qr/\QUsage: has 'name' => ( key => value, ... )/,
        "has takes a hash");

    isa_ok(
        $exception,
        "Moose::Exception::InvalidHasProvidedInARole",
        "has takes a hash");

    is(
        $exception->attribute_name,
        'bar',
        "has takes a hash");

    is(
        $exception->role_name,
        'Foo1',
        "has takes a hash");
}

{
    my $exception = exception {
        use Moose::Role;
        Moose::Role->init_meta;
    };

    like(
        $exception,
        qr/Cannot call init_meta without specifying a for_class/,
        "for_class is not given");

    isa_ok(
        $exception,
        "Moose::Exception::InitMetaRequiresClass",
        "for_class is not given");
}

{
    my $exception = exception {
        use Moose::Role;
        Moose::Role->init_meta( (for_class => 'Foo2', metaclass => 'Foo2' ));
    };

    like(
        $exception,
        qr/\QThe Metaclass Foo2 must be loaded. (Perhaps you forgot to 'use Foo2'?)/,
        "Foo2 is not loaded");

    isa_ok(
        $exception,
        "Moose::Exception::MetaclassNotLoaded",
        "Foo2 is not loaded");

    is(
        $exception->class_name,
        "Foo2",
        "Foo2 is not loaded");
}

{
    {
        package Foo3;
        use Moose;
    }

    my $exception = exception {
        use Moose::Role;
        Moose::Role->init_meta( (for_class => 'Foo3', metaclass => 'Foo3' ));
    };

    like(
        $exception,
        qr/\QThe Metaclass Foo3 must be a subclass of Moose::Meta::Role./,
        "Foo3 is a Moose::Role");

    isa_ok(
        $exception,
        "Moose::Exception::MetaclassMustBeASubclassOfMooseMetaRole",
        "Foo3 is a Moose::Role");

    is(
        $exception->role_name,
        "Foo3",
        "Foo3 is a Moose::Role");
}

{
    {
        package Foo3;
        use Moose;
    }

    my $exception = exception {
        use Moose::Role;
        Moose::Role->init_meta( (for_class => 'Foo3' ));
    };

    my $foo3 = Foo3->meta;

    like(
        $exception,
        qr/\QFoo3 already has a metaclass, but it does not inherit Moose::Meta::Role ($foo3). You cannot make the same thing a role and a class. Remove either Moose or Moose::Role./,
        "Foo3 is a Moose class");
        #Foo3 already has a metaclass, but it does not inherit Moose::Meta::Role (Moose::Meta::Class=HASH(0x2d5d160)). You cannot make the same thing a role and a class. Remove either Moose or Moose::Role.

    isa_ok(
        $exception,
        "Moose::Exception::MetaclassIsAClassNotASubclassOfGivenMetaclass",
        "Foo3 is a Moose class");

    is(
        $exception->class_name,
        "Foo3",
        "Foo3 is a Moose class");

    is(
        find_meta($exception->class_name),
        Foo3->meta,
        "Foo3 is a Moose class");

    is(
        $exception->metaclass,
        "Moose::Meta::Role",
        "Foo3 is a Moose class");
}

{
    my $foo;
    {
        $foo = Class::MOP::Class->create("Foo4");
    }

    my $exception = exception {
        use Moose::Role;
        Moose::Role->init_meta( (for_class => 'Foo4' ));
    };

    like(
        $exception,
        qr/\QFoo4 already has a metaclass, but it does not inherit Moose::Meta::Role ($foo)./,
        "Foo4 is a Class::MOP::Class, not a Moose::Meta::Role");
        #Foo4 already has a metaclass, but it does not inherit Moose::Meta::Role (Class::MOP::Class=HASH(0x2c385a8)).

    isa_ok(
        $exception,
        "Moose::Exception::MetaclassIsNotASubclassOfGivenMetaclass",
        "Foo4 is a Class::MOP::Class, not a Moose::Meta::Role");

    is(
        $exception->class_name,
        "Foo4",
        "Foo4 is a Class::MOP::Class, not a Moose::Meta::Role");

    is(
        find_meta( $exception->class_name ),
        $foo,
        "Foo4 is a Class::MOP::Class, not a Moose::Meta::Role");

    is(
        $exception->metaclass,
        "Moose::Meta::Role",
        "Foo4 is a Class::MOP::Class, not a Moose::Meta::Role");
}

{
    my $exception = exception {
        package Foo;
        use Moose::Role;

        before qr/foo/;
    };

    like(
        $exception,
        qr/\QRoles do not currently support regex references for before method modifiers/,
        "a regex reference is given to before");

    isa_ok(
        $exception,
        "Moose::Exception::RolesDoNotSupportRegexReferencesForMethodModifiers",
        "a regex reference is given to before");

    is(
        $exception->role_name,
        "Foo",
        "a regex reference is given to before");

    is(
        find_meta($exception->role_name),
        Foo->meta,
        "a regex reference is given to before");

    is(
        $exception->modifier_type,
        "before",
        "a regex reference is given to before");
}

done_testing;
