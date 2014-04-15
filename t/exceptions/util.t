
use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose::Util qw/apply_all_roles add_method_modifier/;

{
    {
        package TestClass;
        use Moose;
    }

    my $test_object = TestClass->new;

    my $exception = exception {
        apply_all_roles( $test_object );
    };

    like(
        $exception,
        qr/\QMust specify at least one role to apply to $test_object/,
        "apply_all_roles takes an object and a role to apply");
        #Must specify at least one role to apply to TestClass=HASH(0x2bee290)

    isa_ok(
        $exception,
        "Moose::Exception::MustSpecifyAtleastOneRoleToApplicant",
        "apply_all_roles takes an object and a role to apply");

    my $test_class = TestClass->meta;

    $exception = exception {
        apply_all_roles( $test_class );
    };

    like(
        $exception,
        qr/\QMust specify at least one role to apply to $test_class/,
        "apply_all_roles takes a class and a role to apply");
        #Must specify at least one role to apply to Moose::Meta::Class=HASH(0x1a1f818)

    isa_ok(
        $exception,
        "Moose::Exception::MustSpecifyAtleastOneRoleToApplicant",
        "apply_all_roles takes a class and a role to apply");

    {
        package TestRole;
        use Moose::Role;
    }

    my $test_role = TestRole->meta;

    $exception = exception {
        apply_all_roles( $test_role );
    };

    like(
        $exception,
        qr/\QMust specify at least one role to apply to $test_role/,
        "apply_all_roles takes a role and a role to apply");
        #Must specify at least one role to apply to Moose::Meta::Role=HASH(0x1f22d40)

    isa_ok(
        $exception,
        "Moose::Exception::MustSpecifyAtleastOneRoleToApplicant",
        "apply_all_roles takes a role and a role to apply");
}

# tests for class consuming a class, instead of role
{
    my $exception = exception {
        package ClassConsumingClass;
        use Moose;
        use Module::Runtime;
        with 'Module::Runtime';
    };

    like(
        $exception,
        qr/You can only consume roles, Module::Runtime is not a Moose role/,
        "You can't consume a class");

    isa_ok(
         $exception,
        'Moose::Exception::CanOnlyConsumeRole',
        "You can't consume a class");

    $exception = exception {
        package foo;
        use Moose;
        use Module::Runtime;
        with 'Not::A::Real::Package';
    };

    like(
        $exception,
        qr!Can't locate Not/A/Real/Package\.pm in \@INC!,
        "You can't consume a class which doesn't exist");

    $exception = exception {
        package foo;
        use Moose;
        use Module::Runtime;
        with sub {};
    };

    like(
        $exception,
        qr/argument is not a module name/,
        "You can only consume a module");
}

{
    {
	package Foo;
	use Moose;
    }

    my $exception = exception {
	add_method_modifier(Foo->meta, "before", [{}, sub {"before";}]);
    };

    like(
        $exception,
        qr/\QMethods passed to before must be provided as a list, arrayref or regex, not HASH/,
        "we gave a HashRef to before");

    isa_ok(
        $exception,
        "Moose::Exception::IllegalMethodTypeToAddMethodModifier",
        "we gave a HashRef to before");

    is(
	ref( $exception->params->[0] ),
	"HASH",
        "we gave a HashRef to before");

    is(
	$exception->modifier_name,
	'before',
        "we gave a HashRef to before");

    is(
	$exception->class_or_object->name,
	"Foo",
        "we gave a HashRef to before");
}

{
    my $exception = exception {
        package My::Class;
        use Moose;
        has 'attr' => (
            is     => 'ro',
            traits => [qw( Xyz )],
        );
    };

    like(
        $exception,
        qr/^Can't locate Moose::Meta::Attribute::Custom::Trait::Xyz or Xyz in \@INC \(\@INC contains:/,
        "Cannot locate 'Xyz'");

    isa_ok(
        $exception,
        "Moose::Exception::CannotLocatePackageInINC",
        "Cannot locate 'Xyz'");

    is(
	$exception->type,
	"Attribute",
        "Cannot locate 'Xyz'");

    is(
	$exception->possible_packages,
	'Moose::Meta::Attribute::Custom::Trait::Xyz or Xyz',
        "Cannot locate 'Xyz'");

    is(
	$exception->metaclass_name,
	"Xyz",
        "Cannot locate 'Xyz'");
}

done_testing;
