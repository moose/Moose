
use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose();

use Moose::Util 'find_meta';

{
    {
        package BarRole;
        use Moose::Role;
    }

    {
        package RoleExcludingBarRole;
        use Moose::Role;
        excludes 'BarRole';
    }

    my $exception = exception {
        {
            package FooClass;
            use Moose;

            with 'RoleExcludingBarRole';
            with 'BarRole';
        }
    };

    like(
        $exception,
        qr/\QConflict detected: FooClass excludes role 'BarRole'/,
        'class FooClass excludes Role BarRole');

    isa_ok(
        $exception,
        "Moose::Exception::ConflictDetectedInCheckRoleExclusionsInToClass",
        'class FooClass excludes Role BarRole');

    is(
        $exception->class_name,
        "FooClass",
        'class FooClass excludes Role BarRole');

    is(
        find_meta($exception->class_name),
        FooClass->meta,
        'class FooClass excludes Role BarRole');

    is(
        $exception->role_name,
        "BarRole",
        'class FooClass excludes Role BarRole');

    is(
        find_meta($exception->role_name),
        BarRole->meta,
        'class FooClass excludes Role BarRole');
}

{
    {
        package BarRole2;
        use Moose::Role;
        excludes 'ExcludedRole2';
    }

    {
        package ExcludedRole2;
        use Moose::Role;
    }

    my $exception = exception {
        {
            package FooClass2;
            use Moose;

            with 'ExcludedRole2';
            with 'BarRole2';
        }
    };

    like(
        $exception,
        qr/\QThe class FooClass2 does the excluded role 'ExcludedRole2'/,
        'Class FooClass2 does Role ExcludedRole2');

    isa_ok(
        $exception,
        "Moose::Exception::ClassDoesTheExcludedRole",
        'Class FooClass2 does Role ExcludedRole2');

    is(
        $exception->role_name,
        "BarRole2",
        'Class FooClass2 does Role ExcludedRole2');

    is(
        find_meta($exception->role_name),
        BarRole2->meta,
        'Class FooClass2 does Role ExcludedRole2');

    is(
        $exception->excluded_role_name,
        "ExcludedRole2",
        'Class FooClass2 does Role ExcludedRole2');

    is(
        find_meta($exception->excluded_role_name),
        ExcludedRole2->meta,
        'Class FooClass2 does Role ExcludedRole2');

    is(
        $exception->class_name,
        "FooClass2",
        'Class FooClass2 does Role ExcludedRole2');

    is(
        find_meta($exception->class_name),
        FooClass2->meta,
        'Class FooClass2 does Role ExcludedRole2');
}

{
    {
        package Foo5;
        use Moose::Role;

        sub foo5 { "foo" }
    }

    my $exception = exception {
        {
            package Bar5;
            use Moose;
            with 'Foo5' => {
                -alias    => { foo5 => 'foo_in_bar' }
            };

            sub foo_in_bar { "test in foo" }
        }
    };

    like(
        $exception,
        qr/\QCannot create a method alias if a local method of the same name exists/,
        "Class Bar5 already has a method named foo_in_bar");

    isa_ok(
        $exception,
        "Moose::Exception::CannotCreateMethodAliasLocalMethodIsPresentInClass",
        "Class Bar5 already has a method named foo_in_bar");

    is(
        $exception->role_name,
        "Foo5",
        "Class Bar5 already has a method named foo_in_bar");

    is(
        find_meta($exception->role_name),
        Foo5->meta,
        "Class Bar5 already has a method named foo_in_bar");

    is(
        $exception->class_name,
        "Bar5",
        "Class Bar5 already has a method named foo_in_bar");

    is(
        find_meta($exception->class_name),
        Bar5->meta,
        "Class Bar5 already has a method named foo_in_bar");

    is(
        $exception->aliased_method_name,
        "foo_in_bar",
        "Class Bar5 already has a method named foo_in_bar");

    is(
        $exception->method->name,
        "foo5",
        "Class Bar5 already has a method named foo_in_bar");
}

{
    {
        package Foo::Role;
        use Moose::Role;

        sub foo { 'Foo::Role::foo' }
    }

    {
        package Bar::Role;
        use Moose::Role;

        sub foo { 'Bar::Role::foo' }
    }

    {
        package Baz::Role;
        use Moose::Role;

        sub foo { 'Baz::Role::foo' }
    }

    my $exception = exception {
        {
            package My::Foo::Class::Broken;
            use Moose;

            with 'Foo::Role',
                 'Bar::Role',
                 'Baz::Role' => { -excludes => 'foo' };
        }
    };

    like(
        $exception,
        qr/\QDue to a method name conflict in roles 'Bar::Role' and 'Foo::Role', the method 'foo' must be implemented or excluded by 'My::Foo::Class::Broken'/,
        'Foo::Role, Bar::Role & Baz::Role, all three has a method named foo');

    isa_ok(
        $exception,
        "Moose::Exception::MethodNameConflictInRoles",
        'Foo::Role, Bar::Role & Baz::Role, all three has a method named foo');

    is(
        $exception->class_name,
        "My::Foo::Class::Broken",
        'Foo::Role, Bar::Role & Baz::Role, all three has a method named foo');

    is(
        find_meta($exception->class_name),
        My::Foo::Class::Broken->meta,
        'Foo::Role, Bar::Role & Baz::Role, all three has a method named foo');

    is(
        $exception->get_method_at(0)->name,
        "foo",
        'Foo::Role, Bar::Role & Baz::Role, all three has a method named foo');

    is(
        $exception->get_method_at(0)->roles_as_english_list,
        "'Bar::Role' and 'Foo::Role'",
        'Foo::Role, Bar::Role & Baz::Role, all three has a method named foo');
}

{
    {
        package Foo2::Role;
        use Moose::Role;

        sub foo { 'Foo2::Role::foo' }
        sub bar { 'Foo2::Role::bar' }
    }

    {
        package Bar2::Role;
        use Moose::Role;

        sub foo { 'Bar2::Role::foo' }
        sub bar { 'Bar2::Role::bar' }
    }

    {
        package Baz2::Role;
        use Moose::Role;

        sub foo { 'Baz2::Role::foo' }
        sub bar { 'Baz2::Role::bar' }
    }

    my $exception = exception {
        {
            package My::Foo::Class::Broken2;
            use Moose;

            with 'Foo2::Role',
                 'Bar2::Role',
                 'Baz2::Role';
        }
    };

    like(
        $exception,
        qr/\QDue to method name conflicts in roles 'Bar2::Role' and 'Foo2::Role', the methods 'bar' and 'foo' must be implemented or excluded by 'My::Foo::Class::Broken2'/,
        'Foo2::Role, Bar2::Role & Baz2::Role, all three has a methods named foo & bar');

    isa_ok(
        $exception,
        "Moose::Exception::MethodNameConflictInRoles",
        'Foo2::Role, Bar2::Role & Baz2::Role, all three has a methods named foo & bar');

    is(
        $exception->class_name,
        "My::Foo::Class::Broken2",
        'Foo2::Role, Bar2::Role & Baz2::Role, all three has a methods named foo & bar');

    is(
        find_meta($exception->class_name),
        My::Foo::Class::Broken2->meta,
        'Foo2::Role, Bar2::Role & Baz2::Role, all three has a methods named foo & bar');

    is(
        $exception->get_method_at(0)->roles_as_english_list,
        "'Bar2::Role' and 'Foo2::Role'",
        'Foo2::Role, Bar2::Role & Baz2::Role, all three has a methods named foo & bar');
}

{
    {
        package Foo3::Role;
        use Moose::Role;
        requires 'foo';
    }

    {
        package Bar3::Role;
        use Moose::Role;
    }

    {
        package Baz3::Role;
        use Moose::Role;
    }

    my $exception = exception {
        {
            package My::Foo::Class::Broken3;
            use Moose;
            with 'Foo3::Role',
                 'Bar3::Role',
                 'Baz3::Role';
        }
    };

    like(
        $exception,
        qr/\Q'Foo3::Role|Bar3::Role|Baz3::Role' requires the method 'foo' to be implemented by 'My::Foo::Class::Broken3'/,
        "foo is required by Foo3::Role, but it's not implemented by My::Foo::Class::Broken3");

    isa_ok(
        $exception,
        "Moose::Exception::RequiredMethodsNotImplementedByClass",
        "foo is required by Foo3::Role, but it's not implemented by My::Foo::Class::Broken3");

    is(
        $exception->class_name,
        "My::Foo::Class::Broken3",
        "foo is required by Foo3::Role, but it's not implemented by My::Foo::Class::Broken3");

    is(
        find_meta($exception->class_name),
        My::Foo::Class::Broken3->meta,
        "foo is required by Foo3::Role, but it's not implemented by My::Foo::Class::Broken3");

    is(
        $exception->role_name,
        'Foo3::Role|Bar3::Role|Baz3::Role',
        "foo is required by Foo3::Role, but it's not implemented by My::Foo::Class::Broken3");

    is(
        $exception->get_method_at(0)->name,
        "foo",
        "foo is required by Foo3::Role, but it's not implemented by My::Foo::Class::Broken3");
}

{
    BEGIN {
        package ExportsFoo;
        use Sub::Exporter -setup => {
            exports => ['foo'],
        };

        sub foo { 'FOO' }

        $INC{'ExportsFoo.pm'} = 1;
    }

    {
        package Foo4::Role;
        use Moose::Role;
        requires 'foo';
    }

    my $exception = exception {
        {
            package Class;
            use Moose;
            use ExportsFoo 'foo';
            with 'Foo4::Role';
        }
    };

    my $methodName = "\\&foo";

    like(
        $exception,
        qr/\Q'Foo4::Role' requires the method 'foo' to be implemented by 'Class'. If you imported functions intending to use them as methods, you need to explicitly mark them as such, via Class->meta->add_method(foo => $methodName)/,
        "foo is required by Foo4::Role and imported by Class");

    isa_ok(
        $exception,
        "Moose::Exception::RequiredMethodsImportedByClass",
        "foo is required by Foo4::Role and imported by Class");

    is(
        $exception->class_name,
        "Class",
        "foo is required by Foo4::Role and imported by Class");

    is(
        find_meta($exception->class_name),
        Class->meta,
        "foo is required by Foo4::Role and imported by Class");

    is(
        $exception->role_name,
        'Foo4::Role',
        "foo is required by Foo4::Role and imported by Class");

    is(
        $exception->get_method_at(0)->name,
        "foo",
        "foo is required by Foo4::Role and imported by Class");
}

done_testing;
