#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    {
        package Foo;
        use Moose;
    }

    my $foo = Foo->new;
    my $blessed_foo = blessed $foo;
    my %args = ( "for" => $foo );

    my $exception = exception {
        Moose::Util::MetaRole::apply_metaroles( %args );
    };

    my $message = "When using Moose::Util::MetaRole, "
        ."you must pass a Moose class name, role name, metaclass object, or metarole object."
        ." You passed $foo, and we resolved this to a $blessed_foo object.";

    like(
        $exception,
        qr/\Q$message/,
        "$foo is an object, not a class");

    isa_ok(
        $exception,
        'Moose::Exception::InvalidArgPassedToMooseUtilMetaRole',
        "$foo is an object, not a class");

    is(
        $exception->argument,
        $foo,
        "$foo is an object, not a class");
}

{
    my $array_ref = [1, 2, 3];
    my %args = ( "for" => $array_ref );

    my $exception = exception {
        Moose::Util::MetaRole::apply_metaroles( %args );
    };

    my $message = "When using Moose::Util::MetaRole, "
        ."you must pass a Moose class name, role name, metaclass object, or metarole object."
        ." You passed $array_ref, and this did not resolve to a metaclass or metarole."
        ." Maybe you need to call Moose->init_meta to initialize the metaclass first?";

    like(
        $exception,
        qr/\Q$message/,
        "an Array ref is passed to apply_metaroles");

    isa_ok(
        $exception,
        'Moose::Exception::InvalidArgPassedToMooseUtilMetaRole',
        "an Array ref is passed to apply_metaroles");

    is(
        $exception->argument,
        $array_ref,
        "an Array ref is passed to apply_metaroles");
}

{
    my %args = ( "for" => undef );

    my $exception = exception {
        Moose::Util::MetaRole::apply_metaroles( %args );
    };

    my $message = "When using Moose::Util::MetaRole, "
        ."you must pass a Moose class name, role name, metaclass object, or metarole object."
        ." You passed undef, and this did not resolve to a metaclass or metarole."
        ." Maybe you need to call Moose->init_meta to initialize the metaclass first?";

    like(
        $exception,
        qr/\Q$message/,
        "undef passed to apply_metaroles");

    isa_ok(
        $exception,
        'Moose::Exception::InvalidArgPassedToMooseUtilMetaRole',
        "undef passed to apply_metaroles");

    is(
        $exception->argument,
        undef,
        "undef passed to apply_metaroles");
}

{
    {
        package Foo::Role;
        use Moose::Role;
    }

    my %args = ('for' => "Foo::Role" );

    my $exception = exception {
        Moose::Util::MetaRole::apply_base_class_roles( %args );
    };

    like(
        $exception,
        qr/\QYou can only apply base class roles to a Moose class, not a role./,
        "Moose::Util::MetaRole::apply_base_class_roles expects a class for 'for'");

    isa_ok(
        $exception,
        'Moose::Exception::CannotApplyBaseClassRolesToRole',
        "Moose::Util::MetaRole::apply_base_class_roles expects a class for 'for'");

    is(
        $exception->role_name,
        'Foo::Role',
        "Moose::Util::MetaRole::apply_base_class_roles expects a class for 'for'");
}

done_testing;
