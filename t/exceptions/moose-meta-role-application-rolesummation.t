
use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose();

{
    {
        package Foo1;
        use Moose::Role;
        excludes 'Bar1';
    }

    {
        package Bar1;
        use Moose::Role;
    }

    my $exception = exception {
        package CompositeRole;
        use Moose::Role;
        with 'Foo1', 'Bar1';
    };

    like(
        $exception,
        qr/\QConflict detected: Role Foo1 excludes role 'Bar1'/,
        "role Foo1 excludes role Bar1");

    isa_ok(
        $exception,
        "Moose::Exception::RoleExclusionConflict",
        "role Foo1 excludes role Bar1");

    is(
        $exception->role_name,
        "Bar1",
        "role Foo1 excludes role Bar1");

    is_deeply(
        $exception->roles,
        ["Foo1"],
        "role Foo1 excludes role Bar1");

    {
        package Baz1;
        use Moose::Role;
        excludes 'Bar1';
    }

    $exception = exception {
        package CompositeRole1;
        use Moose::Role;
        with 'Foo1', 'Bar1', 'Baz1';
    };

    like(
        $exception,
        qr/\QConflict detected: Roles Foo1, Baz1 exclude role 'Bar1'/,
        "role Foo1 & Baz1 exclude role Bar1");

    isa_ok(
        $exception,
        "Moose::Exception::RoleExclusionConflict",
        "role Foo1 & Baz1 exclude role Bar1");

    is(
        $exception->role_name,
        "Bar1",
        "role Foo1 & Baz1 exclude role Bar1");

    is_deeply(
        $exception->roles,
        ["Foo1", 'Baz1'],
        "role Foo1 & Baz1 exclude role Bar1");
}

{
    {
        package Foo2;
        use Moose::Role;

        has 'foo' => ( isa => 'Int' );
    }

    {
        package Bar2;
        use Moose::Role;

        has 'foo' => ( isa => 'Int' );
    }

    my $exception = exception {
        package CompositeRole2;
        use Moose::Role;
        with 'Foo2', 'Bar2';
    };

    like(
        $exception,
        qr/\QWe have encountered an attribute conflict with 'foo' during role composition.  This attribute is defined in both Foo2 and Bar2. This is a fatal error and cannot be disambiguated./,
        "role Foo2 & Bar2, both have an attribute named foo");

    isa_ok(
        $exception,
        "Moose::Exception::AttributeConflictInSummation",
        "role Foo2 & Bar2, both have an attribute named foo");

    is(
        $exception->role_name,
        "Foo2",
        "role Foo2 & Bar2, both have an attribute named foo");

    is(
        $exception->second_role_name,
        "Bar2",
        "role Foo2 & Bar2, both have an attribute named foo");

    is(
        $exception->attribute_name,
        "foo",
        "role Foo2 & Bar2, both have an attribute named foo");
}

{
    {
        package Foo3;
        use Moose::Role;

        sub foo {}
    }

    {
        package Bar3;
        use Moose::Role;

        override 'foo' => sub {}
    }

    my $exception = exception {
        package CompositeRole3;
        use Moose::Role;
        with 'Foo3', 'Bar3';
    };

    like(
        $exception,
        qr/\QRole 'Foo3|Bar3' has encountered an 'override' method conflict during composition (A local method of the same name has been found). This is a fatal error./,
        "role Foo3 has a local method 'foo' & role Bar3 is overriding that same method");

    isa_ok(
        $exception,
        "Moose::Exception::OverrideConflictInSummation",
        "role Foo3 has a local method 'foo' & role Bar3 is overriding that same method");

    my @role_names = $exception->role_names;
    my $role_names = join "|", @role_names;
    is(
        $role_names,
        "Foo3|Bar3",
        "role Foo3 has a local method 'foo' & role Bar3 is overriding that same method");

    is(
        $exception->method_name,
        "foo",
        "role Foo3 has a local method 'foo' & role Bar3 is overriding that same method");
}

{
    {
        package Foo4;
        use Moose::Role;

        override 'foo' => sub {};
   }

    {
        package Bar4;
        use Moose::Role;

        override 'foo' => sub {};
    }

    my $exception = exception {
        package CompositeRole4;
        use Moose::Role;
        with 'Foo4', 'Bar4';
    };

    like(
        $exception,
        qr/\QWe have encountered an 'override' method conflict during composition (Two 'override' methods of the same name encountered). This is fatal error./,
        "role Foo4 & Bar4, both are overriding the same method 'foo'");

    isa_ok(
        $exception,
        "Moose::Exception::OverrideConflictInSummation",
        "role Foo4 & Bar4, both are overriding the same method 'foo'");

    my @role_names = $exception->role_names;
    my $role_names = join "|", @role_names;
    is(
        $role_names,
        "Foo4|Bar4",
        "role Foo4 & Bar4, both are overriding the same method 'foo'");

    is(
        $exception->method_name,
        "foo",
        "role Foo4 & Bar4, both are overriding the same method 'foo'");
}

done_testing;
