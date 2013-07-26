#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

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
        $exception->role->name,
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
        $exception->role->name,
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

done_testing;
