#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Try::Tiny;

# tests for extends without arguments
{
    like(
        exception {
            package SubClassNoSuperClass;
            use Moose;
            extends;
        }, qr/Must derive at least one class/,
        "extends requires at least one argument");

    isa_ok(
        exception {
            package SubClassNoSuperClass;
            use Moose;
            extends;
        }, 'Moose::Exception::ExtendsMissingArgs',
        "extends requires at least one argument");
}

# tests for class consuming a class, instead of role
{
    like(
        exception {
            package ClassConsumingClass;
            use Moose;
            use DateTime;
            with 'DateTime';
        }, qr/You can only consume roles, DateTime is not a Moose role/,
        "You can't consume a class");

    isa_ok(
        exception {
            package ClassConsumingClass;
            use Moose;
            use DateTime;
            with 'DateTime';
	}, 'Moose::Exception::CanOnlyConsumeRole',
        "You can't consume a class");

    like(
        exception {
            package foo;
            use Moose;
	    use DateTime;
            with 'Not::A::Real::Package';
        }, qr!You can only consume roles, Not::A::Real::Package is not a Moose role!,
        "You can't consume a class which doesn't exist");

    like(
        exception {
            package foo;
            use Moose;
	    use DateTime;
            with sub {};
        }, qr/argument is not a module name/,
        "You can only consume a module");
}

# tests for type/subtype name contain invalid characters
{
    like(
        exception {
            use Moose::Util::TypeConstraints;
            subtype 'Foo-Baz' => as 'Item'
        }, qr/contains invalid characters/,
        "Type names cannot contain a dash (via subtype sugar)");

    isa_ok(
        exception {
            use Moose::Util::TypeConstraints;
            subtype 'Foo-Baz' => as 'Item';
        }, "Moose::Exception::InvalidNameForType",
        "Type names cannot contain a dash (via subtype sugar)");
}

# tests for type coercions
{
    use Moose;
    use Moose::Util::TypeConstraints;
    subtype 'HexNum' => as 'Int', where { /[a-f0-9]/i };
    my $type_object = find_type_constraint 'HexNum';

    my $exception = exception {
        $type_object->coerce;
    };

    like(
        $exception,
        qr/Cannot coerce without a type coercion/,
        "You cannot coerce a type unless coercion is supported by that type");

    is(
        $exception->type->name,
        'HexNum',
        "You cannot coerce a type unless coercion is supported by that type");

    isa_ok(
        $exception,
        "Moose::Exception::CoercingWithoutCoercions",
        "You cannot coerce a type unless coercion is supported by that type");
}

# tests for AccessorMustReadWrite
{
    use Moose;

    my $exception = exception {
        has 'test' => (
            is       => 'ro',
            isa      => 'Int',
            accessor => 'bar',
        )
    };

    like(
        $exception,
        qr!Cannot define an accessor name on a read-only attribute, accessors are read/write!,
        "Read-only attributes can't have accessor");

    is(
        $exception->attribute_name,
        'test',
        "Read-only attributes can't have accessor");

    isa_ok(
        $exception,
        "Moose::Exception::AccessorMustReadWrite",
        "Read-only attributes can't have accessor");
}

# tests for SingleParamsToNewMustBeHashRef
{
    {
        package Foo;
        use Moose;
    }

    my $exception = exception {
        Foo->new("hello")
    };

    like(
        $exception,
        qr/^\QSingle parameters to new() must be a HASH ref/,
        "A single non-hashref arg to a constructor throws an error");

    isa_ok(
        $exception,
        "Moose::Exception::SingleParamsToNewMustBeHashRef",
        "A single non-hashref arg to a constructor throws an error");
}

# tests for DoesRequiresRoleName
{
    {
        package Foo;
        use Moose;
    }

    my $foo = Foo->new;

    my $exception = exception {
        $foo->does;
    };

    like(
        $exception,
        qr/^\QYou must supply a role name to does()/,
        "Cannot call does() without a role name");

    isa_ok(
        $exception,
        "Moose::Exception::DoesRequiresRoleName",
        "Cannot call does() without a role name");
}

# tests for AttributeIsRequired
{
    {
       package Foo;
       use Moose;

       has 'baz' => (
            is       => 'ro',
            isa      => 'Int',
            required => 1,
       );
    }

    my $exception = exception {
       Foo->new;
    };

    like(
        $exception,
        qr/\QAttribute (baz) is required/,
        "... must supply all the required attribute");

    is(
        $exception->attribute->name,
        'baz',
        "... must supply all the required attribute");

    isa_ok(
        $exception->instance,
        'Foo',
        "... must supply all the required attribute");

    isa_ok(
        $exception,
        "Moose::Exception::AttributeIsRequired",
        "... must supply all the required attribute");
}

# tests for invalid value for is
{
    my $exception = exception {
        use Moose;
        has 'foo' => (
            is => 'bar',
        );
    };

    like(
        $exception,
        qr/^\QI do not understand this option (is => bar) on attribute (foo)/,
        "invalid value for is");

    isa_ok(
        $exception,
        'Moose::Exception::InvalidValueForIs',
        "invalid value for is");
}

{
    {
        package Foo;
        use Moose;
    }

    my $exception = exception {
        use Moose;
        has 'bar' => (
            is   => 'ro',
            isa  => 'Foo',
            does => 'Not::A::Role'
        );
    };

    like(
        $exception,
        qr/^\QCannot have an isa option and a does option if the isa does not do the does on attribute (bar)/,
        "isa option should does the role on the given attribute");

    isa_ok(
        $exception,
        'Moose::Exception::IsaDoesNotDoTheRole',
        "isa option should does the role on the given attribute");
}

{
    {
        package Foo;
        use Moose;
    }

    my $exception = exception {
        has 'bar' => (
            is   => 'ro',
            isa  => 'Not::A::Class',
            does => 'Not::A::Role',
        );
    };

    like(
        $exception,
        qr/^\QCannot have an isa option which cannot ->does() on attribute (bar)/,
        "isa option which is not a class cannot ->does the role specified in does");

    isa_ok(
        $exception,
        'Moose::Exception::IsaLacksDoesMethod',
        "isa option which is not a class cannot ->does the role specified in does");
}

{
    my $exception = exception {
        use Moose;
        has 'bar' => (
            is     => 'ro',
            coerce => 1,
        );
    };

    like(
        $exception,
        qr/^\QYou cannot have coercion without specifying a type constraint on attribute (bar)/,
        "cannot coerce if type constraint i.e. isa option is not given");

    isa_ok(
        $exception,
        'Moose::Exception::CoercionNeedsTypeConstraint',
        "cannot coerce if type constraint i.e. isa option is not given");
}

{
    my $exception = exception {
        use Moose;
        has 'bar' => (
            is       => 'ro',
            isa      => 'Int',
            weak_ref => 1,
            coerce   => 1,
        );
    };

    like(
        $exception,
        qr/^\QYou cannot have a weak reference to a coerced value on attribute (bar)/,
        "cannot coerce if attribute is a weak_ref");

    isa_ok(
        $exception,
        'Moose::Exception::CannotCoerceAWeakRef',
        "cannot coerce if attribute is a weak_ref");
}

{
    my $exception = exception {
        use Moose;
        has 'bar' => (
            is       => 'ro',
            isa      => 'Int',
            trigger  => "foo",
        );
    };

    like(
        $exception,
        qr/^\QTrigger must be a CODE ref on attribute (bar)/,
        "Trigger must be a CODE ref");

    isa_ok(
        $exception,
        'Moose::Exception::TriggerMustBeACodeRef',
        "Trigger must be a CODE ref");
}

{
    {
        package Foo;
        use Moose;
        has 'baz' => (
            is       => 'ro',
            isa      => 'Int',
            builder  => "_build_baz",
        );
    }

    my $exception = exception {
	Foo->new;
    };

    like(
        $exception,
        qr/^\QFoo does not support builder method '_build_baz' for attribute 'baz'/,
        "Correct error when a builder method is not present");

    isa_ok(
        $exception,
        'Moose::Exception::BuilderDoesNotExist',
        "Correct error when a builder method is not present");

    isa_ok(
        $exception->instance,
	'Foo',
        "Correct error when a builder method is not present");

    is(
	$exception->attribute->name,
	'baz',
        "Correct error when a builder method is not present");

    is(
        $exception->attribute->builder,
        '_build_baz',
        "Correct error when a builder method is not present");
}

# tests for Moose::Meta::Class::add_role
{
    use Moose::Meta::Class;

    {
        package Foo;
        use Moose;
    }

    my $exception = exception {
        Foo->meta->does_role;
    };

    like(
        $exception,
        qr/You must supply a role name to look for/,
        "Cannot call does_role without a role name");

    isa_ok(
        $exception,
        'Moose::Exception::RoleNameRequired',
        "Cannot call does_role without a role name");
}

{
    use Moose::Meta::Class;

    {
        package Foo;
        use Moose;
    }

    my $exception = exception {
        Foo->meta->add_role('Bar');
    };

    like(
        $exception,
        qr/Roles must be instances of Moose::Meta::Role/,
        "add_role takes an instance of Moose::Meta::Role");

    isa_ok(
        $exception,
        'Moose::Exception::AddRoleTakesAMooseMetaRoleInstance',
        "add_role takes an instance of Moose::Meta::Role");
}

# tests for Moose::Meta::Class::excludes_role
{
    use Moose::Meta::Class;

    {
        package Foo;
        use Moose;
    }

    my $exception = exception {
        Foo->meta->excludes_role;
    };

    like(
        $exception,
        qr/You must supply a role name to look for/,
        "Cannot call excludes_role without a role name");

    isa_ok(
        $exception,
        'Moose::Exception::RoleNameRequired',
        "Cannot call excludes_role without a role name");
}

{
    {
        package Bar;
        use Moose::Role;
    }

    my $exception = exception {
        package Foo;
        use Moose;
        extends 'Bar';
    };

    like(
        $exception,
        qr/^\QYou cannot inherit from a Moose Role (Bar)/,
        "Class cannot extend a role");

    isa_ok(
        $exception,
        'Moose::Exception::CanExtendOnlyClasses',
        "Class cannot extend a role");

    is(
	$exception->role->name,
	'Bar',
	"Class cannot extend a role");
}

# tests for AttributeIsRequired for inline excpetions
{
    use Moose::Meta::Class;

    {
	package Foo;
	use Moose;

	has 'baz' => (
	    is => 'ro',
	    isa => 'Int',
	    required => 1,
	    );
    }

    __PACKAGE__->meta->make_immutable;
    my $exception = exception {
	my $test1 = Foo->new;
    };

    like(
        $exception,
        qr/\QAttribute (baz) is required/,
        "... must supply all the required attribute");

    is(
        $exception->attribute->name,
        'baz',
        "... must supply all the required attribute");

    isa_ok(
        $exception->instance,
        'Foo',
        "... must supply all the required attribute");

    isa_ok(
        $exception,
        "Moose::Exception::AttributeIsRequired",
        "... must supply all the required attribute");
}

# tests for CannotDelegateWithoutIsa
{
    my $exception = exception {
	package Foo;
	use Moose;
	has 'bar' => (
	    is      => 'ro',
	    handles => qr/baz/,
	);
    };

    like(
        $exception,
        qr/\QCannot delegate methods based on a Regexp without a type constraint (isa)/,
        "isa is required while delegating methods based on a Regexp");

    isa_ok(
        $exception,
        'Moose::Exception::CannotDelegateWithoutIsa',
        "isa is required while delegating methods based on a Regexp");
}

{
    my $exception = exception {
	package Foo;
	use Moose;
	has bar => (
	    is         => 'ro',
	    auto_deref => 1,
        );
    };

    like(
        $exception,
        qr/\QYou cannot auto-dereference without specifying a type constraint on attribute (bar)/,
        "You cannot auto-dereference without specifying a type constraint on attribute");

    isa_ok(
        $exception,
        'Moose::Exception::CannotAutoDerefWithoutIsa',
        "You cannot auto-dereference without specifying a type constraint on attribute");

    is(
	$exception->attribute_name,
	'bar',
        "You cannot auto-dereference without specifying a type constraint on attribute");
}

{
    my $exception = exception {
	package Foo;
	use Moose;
	sub foo {}
	augment foo => sub {};
    };

    like(
        $exception,
        qr/Cannot add an augment method if a local method is already present/,
        "there is already a method named foo defined in the class");

    isa_ok(
        $exception,
        'Moose::Exception::CannotAugmentIfLocalMethodPresent',
        "there is already a method named foo defined in the class");

    is(
	$exception->class->name,
	'Foo',
        "there is already a method named foo defined in the class");

    is(
	$exception->method->name,
	'foo',
        "there is already a method named foo defined in the class");
}

{
    my $exception = exception {
	package Foo;
	use Moose;
	has 'bar' => (
	    is       => 'ro',
	    required => 1,
	    init_arg => undef,
	);
    };

    like(
        $exception,
        qr/\QYou cannot have a required attribute (bar) without a default, builder, or an init_arg/,
        "No default, builder or init_arg is given");

    isa_ok(
        $exception,
        'Moose::Exception::RequiredAttributeNeedsADefault',
        "No default, builder or init_arg is given");
}

{
    my $exception = exception {
	package Foo;
	use Moose;
	has 'bar' => (
	    is   => 'ro',
	    lazy => 1,
	);
    };

    like(
        $exception,
        qr/\QYou cannot have a lazy attribute (bar) without specifying a default value for it/,
        "No default for a lazy attribute is given");

    isa_ok(
        $exception,
        'Moose::Exception::LazyAttributeNeedsADefault',
        "No default for a lazy attribute is given");
}

{
    my $exception = exception {
	package Foo;
	use Moose;
	has 'bar' => (
	    is         => 'ro',
	    isa        => 'Int',
	    auto_deref => 1,
	);
    };

    like(
        $exception,
        qr/\QYou cannot auto-dereference anything other than a ArrayRef or HashRef on attribute (bar)/,
        "auto_deref needs either HashRef or ArrayRef");

    isa_ok(
        $exception,
        'Moose::Exception::AutoDeRefNeedsArrayRefOrHashRef',
        "auto_deref needs either HashRef or ArrayRef");
}

{
    my $exception = exception {
	package Foo;
	use Moose;
	has 'bar' => (
	    is         => 'ro',
	    lazy_build => 1,
	    default    => 1,
	);
    };

    like(
        $exception,
        qr/\QYou can not use lazy_build and default for the same attribute (bar)/,
        "An attribute can't use lazy_build & default simultaneously");

    isa_ok(
        $exception,
        'Moose::Exception::CannotUseLazyBuildAndDefaultSimultaneously',
        "An attribute can't use lazy_build & default simultaneously");
}

{
    my $exception = exception {
	package Delegator;
	use Moose;

	sub full { 1 }
	sub stub;

	has d1 => (
	    isa     => 'X',
	    handles => ['full'],
        );
    };

    like(
        $exception,
        qr/\QYou cannot overwrite a locally defined method (full) with a delegation/,
        'got an error when trying to declare a delegation method that overwrites a local method');

    isa_ok(
        $exception,
        'Moose::Exception::CannotDelegateLocalMethodIsPresent',
        "got an error when trying to declare a delegation method that overwrites a local method");

    $exception = exception {
	package Delegator;
	use Moose;

	has d2 => (
	    isa     => 'X',
	    handles => ['stub'],
        );
    };

    is(
	$exception,
        undef,
        'no error when trying to declare a delegation method that overwrites a stub method');
}

{
    my $exception = exception {
	package Foo;
	use Moose;
	sub foo {}
	override foo => sub {};
    };

    like(
        $exception,
        qr/Cannot add an override method if a local method is already present/,
        "there is already a method named foo defined in the class, so you can't override it");

    isa_ok(
        $exception,
        'Moose::Exception::CannotOverrideLocalMethodIsPresent',
        "there is already a method named foo defined in the class, so you can't override it");

    is(
	$exception->class->name,
	'Foo',
        "there is already a method named foo defined in the class, so you can't override it");

    is(
	$exception->method->name,
	'foo',
        "there is already a method named foo defined in the class, so you can't override it");
}

{
    my $exception = exception {
        package Foo;
        use Moose;
	__PACKAGE__->meta->make_immutable;
	Foo->new([])
    };

    like(
        $exception,
        qr/^\QSingle parameters to new() must be a HASH ref/,
        "A single non-hashref arg to a constructor throws an error");

    isa_ok(
        $exception,
        "Moose::Exception::SingleParamsToNewMustBeHashRef",
        "A single non-hashref arg to a constructor throws an error");
}

{
    my $exception =  exception {
	Moose::Meta::Class->create(
	    'Made::Of::Fail',
	    superclasses => ['Class'],
	    roles        => 'Foo',
	    );
    };

    like(
        $exception,
        qr/You must pass an ARRAY ref of roles/,
        "create takes an Array of roles");

    isa_ok(
        $exception,
        "Moose::Exception::RolesInCreateTakesAnArrayRef",
        "create takes an Array of roles");
}

{
    my $exception = exception {
	package Foo;
	use Moose;
	Foo->meta->add_role_application();
    };

    like(
	$exception,
	qr/Role applications must be instances of Moose::Meta::Role::Application::ToClass/,
	"bar is not an instance of Moose::Meta::Role::Application::ToClass");

    isa_ok(
	$exception,
	"Moose::Exception::InvalidRoleApplication",
	"bar is not an instance of Moose::Meta::Role::Application::ToClass");
}

{
    {
	package Test;
	use Moose;
    }

    my $exception = exception {
	package Test2;
	use Moose;
	extends 'Test';
	has '+bar' => ( default => 100 );
    };

    like(
	$exception,
	qr/Could not find an attribute by the name of 'bar' to inherit from in Test2/,
	"attribute 'bar' is not defined in the super class");

    isa_ok(
	$exception,
	"Moose::Exception::NoAttributeFoundInSuperClass",
	"attribute 'bar' is not defined in the super class");
}

{
    {
	package Test;
	use Moose;
	has 'foo' => (
            is        => 'rw',
            clearer   => 'clear_foo',
            predicate => 'foo',
            accessor  => 'bar',
        );
    }

    my $exception = exception {
	package Test2;
	use Moose;
	extends 'Test';
	has '+foo' => (
	    clearer   => 'clear_foo1',
	);
    };

    like(
	$exception,
	qr/\QIllegal inherited options => (clearer)/,
	"Illegal inherited option is given");

    isa_ok(
	$exception,
	"Moose::Exception::IllegalInheritedOptions",
	"Illegal inherited option is given");

    $exception = exception {
	package Test3;
	use Moose;
	extends 'Test';
	has '+foo' => (
            clearer   => 'clear_foo1',
            predicate => 'xyz',
            accessor  => 'bar2',
        );
    };

    like(
	$exception,
	qr/\QIllegal inherited options => (accessor, clearer, predicate)/,
	"Illegal inherited option is given");
}

# tests for exception thrown is Moose::Meta::Attribute::set_value
{
    my $exception = exception {
	{
	    package Foo1;
	    use Moose;
	    has 'bar' => (
		is       => 'ro',
		required => 1,
	    );
	}

	my $instance = Foo1->new(bar => "test");
	my $bar_attr = Foo1->meta->get_attribute('bar');
	my $bar_writer = $bar_attr->get_write_method_ref;
	$bar_writer->($instance);
    };

    like(
        $exception,
        qr/\QAttribute (bar) is required/,
        "... must supply all the required attribute");

    is(
        $exception->attribute->name,
        'bar',
        "... must supply all the required attribute");

    isa_ok(
        $exception->instance,
        'Foo1',
        "... must supply all the required attribute");

    isa_ok(
        $exception,
        "Moose::Exception::AttributeIsRequired",
        "... must supply all the required attribute");
}

{
    my $exception = exception {
	{
	    package Foo1;
	    use Moose;
	    has bar => (
                is       => 'ro',
                required => 1,
                isa      => 'Int',
	    );
	}

	Foo1->new(bar => "test");
    };

    like(
	$exception,
	qr/\QAttribute (bar) does not pass the type constraint because: Validation failed for 'Int' with value "test"/,
	"bar is an 'Int' and 'Str' is given");

    isa_ok(
	$exception,
	"Moose::Exception::ValidationFailedForTypeConstraint",
	"bar is an 'Int' and 'Str' is given");
}

{
    my $exception = exception {
	{
	    package Foo1;
	    use Moose;
	    has 'bar' => (
                is       => 'ro',
                handles  => \*STDIN,
	    );
	}
    };

    my $handle = \*STDIN;

    like(
	$exception,
	qr/\QUnable to canonicalize the 'handles' option with $handle/,
	"handles doesn't take file handle");

    isa_ok(
	$exception,
	"Moose::Exception::UnableToCanonicalizeHandles",
	"handles doesn't take file handle");

}

{
    my $exception = exception {
	{
	    package Foo1;
	    use Moose;
	    has 'bar' => (
                is       => 'ro',
                handles  => 'Foo1',
	    );
	}
    };

    like(
	$exception,
	qr/\QUnable to canonicalize the 'handles' option with Foo1 because its metaclass is not a Moose::Meta::Role/,
	"'Str' given to handles should be a metaclass of Moose::Meta::Role");

    isa_ok(
	$exception,
	"Moose::Exception::UnableToCanonicalizeNonRolePackage",
	"'Str' given to handles should be a metaclass of Moose::Meta::Role");
}

{
    my $exception = exception {
	{
	    package Foo1;
	    use Moose;
	    has 'bar' => (
                is      => 'ro',
                isa     => 'Not::Loaded',
                handles => qr/xyz/,
            );
	}
    };

    like(
	$exception,
	qr/\QThe bar attribute is trying to delegate to a class which has not been loaded - Not::Loaded/,
	"You cannot delegate to a class which has not yet loaded");

    isa_ok(
	$exception,
	"Moose::Exception::DelegationToAClassWhichIsNotLoaded",
	"You cannot delegate to a class which has not yet loaded");

    is(
        $exception->attribute->name,
	'bar',
	"You cannot delegate to a class which has not yet loaded"
    );

    is(
        $exception->class_name,
	'Not::Loaded',
	"You cannot delegate to a class which has not yet loaded"
    );
}

{
    my $exception = exception {
	{
	    package Foo1;
	    use Moose;
	    has bar => (
                is      => 'ro',
                does    => 'Role',
                handles => qr/Role/,
            );
	}
    };

    like(
	$exception,
	qr/\QThe bar attribute is trying to delegate to a role which has not been loaded - Role/,
	"You cannot delegate to a role which has not yet loaded");

    isa_ok(
	$exception,
	"Moose::Exception::DelegationToARoleWhichIsNotLoaded",
	"You cannot delegate to a role which has not yet loaded");

    is(
        $exception->attribute->name,
	'bar',
	"You cannot delegate to a role which has not yet loaded"
    );

    is(
        $exception->role_name,
	'Role',
	"You cannot delegate to a role which has not yet loaded"
    );
}


{
    my $exception = exception {
        {
            package Foo1;
            use Moose;
            has 'bar' => (
                is      => 'ro',
                isa     => 'Int',
                handles => qr/xyz/,
            );
	}
    };

    like(
        $exception,
        qr/\QThe bar attribute is trying to delegate to a type (Int) that is not backed by a class/,
        "Delegating to a type that is not backed by a class");

    isa_ok(
        $exception,
        "Moose::Exception::DelegationToATypeWhichIsNotAClass",
        "Delegating to a type that is not backed by a class");

    is(
        $exception->attribute->name,
        'bar',
        "Delegating to a type that is not backed by a class");

    is(
        $exception->attribute->type_constraint->name,
        'Int',
        "Delegating to a type that is not backed by a class");

    $exception = exception {
        {
            package Foo1;
            use Moose;
            use Moose::Util::TypeConstraints;

            subtype 'PositiveInt',
            as 'Int',
            where { $_ > 0 };

            has 'bar' => (
                is      => 'ro',
                isa     => 'PositiveInt',
                handles => qr/xyz/,
            );
        }
    };

    like(
        $exception,
        qr/\QThe bar attribute is trying to delegate to a type (PositiveInt) that is not backed by a class/,
        "Delegating to a type that is not backed by a class");

    isa_ok(
        $exception,
        "Moose::Exception::DelegationToATypeWhichIsNotAClass",
        "Delegating to a type that is not backed by a class");

    is(
        $exception->attribute->type_constraint->name,
        'PositiveInt',
        "Delegating to a type that is not backed by a class");
}

{
    my $exception = exception {
        {
            package Foo1;
            use Moose;
            has 'bar' => (
                is      => 'ro',
                does    => '',
                handles => qr/xyz/,
            );
        }
    };

    like(
        $exception,
        qr/Cannot find delegate metaclass for attribute bar/,
        "no does or isa is given");

    isa_ok(
        $exception,
        "Moose::Exception::CannotFindDelegateMetaclass",
        "no does or isa is given");

    is(
        $exception->attribute->name,
        'bar',
        "no does or isa is given");
}

{
    my $exception = exception {
        {
            package Foo1;
            use Moose;
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
        "Moose::Exception::BadHasProvided",
        "has takes a hash");

    is(
        $exception->attribute_name,
        'bar',
        "has takes a hash");

    is(
        $exception->class->name,
        'Foo1',
        "has takes a hash");
}

{
    {
	package DoesClassRole;
	use Moose;
	extends 'Moose::Exception';
	with 'Moose::Exception::Role::Class';
    }

    my $exception = exception {
	my $doesClassRole = DoesClassRole->new;
    };

    like(
        $exception,
        qr/\QYou need to give class or class_name or both/,
	"please give either class or class_name");

    isa_ok(
        $exception,
        "Moose::Exception::NeitherClassNorClassNameIsGiven",
        "please give either class or class_name");

    {
	package JustATestClass;
	use Moose;
    }

    $exception = DoesClassRole->new( class => JustATestClass->meta );

    ok( !$exception->is_class_name_set, "class_name is not set");

    is(
	$exception->class->name,
	"JustATestClass",
	"you have given class");

    is(
	$exception->class_name,
	"JustATestClass",
	"you have given class");

    $exception = DoesClassRole->new( class_name => "JustATestClass" );

    ok( !$exception->is_class_set, "class is not set");

    is(
	$exception->class_name,
	"JustATestClass",
	"you have given class");

    is(
	$exception->class->name,
	"JustATestClass",
	"you have given class");

    $exception = DoesClassRole->new( class_name => "DoesClassRole",
				     class      => DoesClassRole->meta
                                   );

    is(
	$exception->class_name,
	"DoesClassRole",
	"you have given both, class & class_name");

    is(
	$exception->class->name,
	"DoesClassRole",
	"you have given both, class & class_name");

    $exception = exception {
        DoesClassRole->new( class_name => "Foo",
                            class      => DoesClassRole->meta,
                          );
    };

    like(
        $exception,
        qr/\Qclass_name (Foo) does not match class->name (DoesClassRole)/,
	"you have given class_name as 'Foo' and class->name as 'DoesClassRole'");

    isa_ok(
        $exception,
        "Moose::Exception::ClassNamesDoNotMatch",
        "you have given class_name as 'Foo' and class->name as 'DoesClassRole'");

    is(
	$exception->class_name,
	"Foo",
	"you have given class_name as 'Foo' and class->name as 'DoesClassRole'");

    is(
	$exception->class->name,
	"DoesClassRole",
	"you have given class_name as 'Foo' and class->name as 'DoesClassRole'");
}

{
    my $exception = exception {
        use Moose;
        Moose->init_meta;
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
        use Moose;
        Moose->init_meta( (for_class => 'Foo2', metaclass => 'Foo2' ));
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
	use Moose::Role;
    }

    my $exception = exception {
        use Moose;
        Moose->init_meta( (for_class => 'Foo3', metaclass => 'Foo3' ));
    };

    like(
        $exception,
        qr/\QThe Metaclass Foo3 must be a subclass of Moose::Meta::Class./,
        "Foo3 is a Moose::Role");

    isa_ok(
        $exception,
        "Moose::Exception::MetaclassMustBeASubclassOfMooseMetaClass",
        "Foo3 is a Moose::Role");

    is(
	$exception->class_name,
	"Foo3",
	"Foo3 is not loaded");
}

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
    {
        package DoesRoleRole;
        use Moose;
        extends 'Moose::Exception';
        with 'Moose::Exception::Role::Role';
    }

    my $exception = exception {
        my $doesRoleRole = DoesRoleRole->new;
    };

    like(
        $exception,
        qr/\QYou need to give role or role_name or both/,
        "please give either role or role_name");

    isa_ok(
        $exception,
        "Moose::Exception::NeitherRoleNorRoleNameIsGiven",
        "please give either role or role_name");

    {
        package JustATestRole;
        use Moose::Role;
    }

    $exception = DoesRoleRole->new( role => JustATestRole->meta );

    ok( !$exception->is_role_name_set, "role_name is not set");

    is(
        $exception->role->name,
        "JustATestRole",
        "you have given role");

    is(
        $exception->role_name,
        "JustATestRole",
        "you have given role");

    $exception = DoesRoleRole->new( role_name => "JustATestRole" );

    ok( !$exception->is_role_set, "role is not set");

    is(
        $exception->role_name,
        "JustATestRole",
        "you have given role");

    is(
        $exception->role->name,
        "JustATestRole",
        "you have given role");

    $exception = DoesRoleRole->new( role_name => "JustATestRole",
                                    role      => JustATestRole->meta
                                  );

    is(
        $exception->role_name,
        "JustATestRole",
        "you have given both, role & role_name");

    is(
        $exception->role->name,
        "JustATestRole",
        "you have given both, role & role_name");

    $exception = exception {
        DoesRoleRole->new( role_name => "Foo",
                           role      => JustATestRole->meta,
                         );
    };

    like(
        $exception,
        qr/\Qrole_name (Foo) does not match role->name (JustATestRole)/,
        "you have given role_name as 'Foo' and role->name as 'JustATestRole'");

    isa_ok(
        $exception,
        "Moose::Exception::RoleNamesDoNotMatch",
        "you have given role_name as 'Foo' and role->name as 'JustATestRole'");

    is(
        $exception->role_name,
        "Foo",
        "you have given role_name as 'Foo' and role->name as 'JustATestRole'");

    is(
        $exception->role->name,
        "JustATestRole",
        "you have given role_name as 'Foo' and role->name as 'JustATestRole'");
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
