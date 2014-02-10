
use strict;
use warnings;

use Test::More;
use Test::Fatal;

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

    isa_ok(
        $exception,
        "Moose::Exception::AccessorMustReadWrite",
        "Read-only attributes can't have accessor");

    is(
        $exception->attribute_name,
        'test',
        "Read-only attributes can't have accessor");
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

    isa_ok(
        $exception,
        "Moose::Exception::AttributeIsRequired",
        "... must supply all the required attribute");

    is(
        $exception->attribute_name,
        'baz',
        "... must supply all the required attribute");

    isa_ok(
        $exception->class_name,
        'Foo',
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

    isa_ok(
        $exception,
        "Moose::Exception::AttributeIsRequired",
        "... must supply all the required attribute");

    is(
        $exception->attribute_name,
        'bar',
        "... must supply all the required attribute");

    isa_ok(
        $exception->class_name,
        'Foo1',
        "... must supply all the required attribute");
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
        #Unable to canonicalize the 'handles' option with GLOB(0x109d0b0)

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

    isa_ok(
        $exception,
        "Moose::Exception::CoercingWithoutCoercions",
        "You cannot coerce a type unless coercion is supported by that type");

    is(
        $exception->type_name,
        'HexNum',
        "You cannot coerce a type unless coercion is supported by that type");
}

{
    {
        package Parent;
        use Moose;

        has foo => (
            is      => 'rw',
            isa     => 'Num',
            default => 5.5,
        );
    }

    {
        package Child;
        use Moose;
        extends 'Parent';

        has '+foo' => (
            isa     => 'Int',
            default => 100,
       );
    }

    my $foo = Child->new;
    my $exception = exception {
        $foo->foo(10.5);
    };

    like(
        $exception,
        qr/\QAttribute (foo) does not pass the type constraint because: Validation failed for 'Int' with value 10.5/,
        "10.5 is not an Int");

    isa_ok(
        $exception,
        "Moose::Exception::ValidationFailedForInlineTypeConstraint",
        "10.5 is not an Int");

    is(
        $exception->class_name,
        "Child",
        "10.5 is not an Int");
}

{
    {
        package Foo2;
        use Moose;

        has a4 => (
            traits  => ['Array'],
            is      => 'rw',
            isa     => 'ArrayRef',
            lazy    => 1,
            default => 'invalid',
            clearer => '_clear_a4',
            handles => {
                get_a4      => 'get',
                push_a4     => 'push',
                accessor_a4 => 'accessor',
            },
        );

        has a5 => (
            traits  => ['Array'],
            is      => 'rw',
            isa     => 'ArrayRef[Int]',
            lazy    => 1,
            default => sub { [] },
            clearer => '_clear_a5',
            handles => {
                get_a5      => 'get',
                push_a5     => 'push',
                accessor_a5 => 'accessor',
            },
        );
    }

    my $foo = Foo2->new;

    my $expect
        = qr/\QAttribute (a4) does not pass the type constraint because: Validation failed for 'ArrayRef' with value \E.*invalid.*/;

    my $exception = exception { $foo->accessor_a4(0); };

    like(
        $exception,
        $expect,
        'invalid default is caught when trying to read via accessor');
        #Attribute (a4) does not pass the type constraint because: Validation failed for 'ArrayRef' with value "invalid"

    isa_ok(
        $exception,
        "Moose::Exception::ValidationFailedForInlineTypeConstraint",
        'invalid default is caught when trying to read via accessor');

    is(
        $exception->class_name,
        "Foo2",
        'invalid default is caught when trying to read via accessor');

    $exception = exception { $foo->accessor_a4( 0 => 42 ); };

    like(
        $exception,
        $expect,
        'invalid default is caught when trying to write via accessor');
        #Attribute (a4) does not pass the type constraint because: Validation failed for 'ArrayRef' with value "invalid"

    isa_ok(
        $exception,
        "Moose::Exception::ValidationFailedForInlineTypeConstraint",
        'invalid default is caught when trying to write via accessor');

    is(
        $exception->class_name,
        "Foo2",
        'invalid default is caught when trying to write via accessor');

    $exception = exception { $foo->push_a4(42); };

    like(
        $exception,
        $expect,
        'invalid default is caught when trying to push');
        #Attribute (a4) does not pass the type constraint because: Validation failed for 'ArrayRef' with value "invalid"

    isa_ok(
        $exception,
        "Moose::Exception::ValidationFailedForInlineTypeConstraint",
        'invalid default is caught when trying to push');

    is(
        $exception->class_name,
        "Foo2",
        'invalid default is caught when trying to push');

    $exception = exception { $foo->get_a4(42); };

    like(
        $exception,
        $expect,
        'invalid default is caught when trying to get');
        #Attribute (a4) does not pass the type constraint because: Validation failed for 'ArrayRef' with value "invalid"

    isa_ok(
        $exception,
        "Moose::Exception::ValidationFailedForInlineTypeConstraint",
        'invalid default is caught when trying to get');

    is(
        $exception->class_name,
        "Foo2",
        'invalid default is caught when trying to get');
}

{
    my $class = Moose::Meta::Class->create("RedundantClass");
    my $attr = Moose::Meta::Attribute->new('foo', (auto_deref => 1,
                                                   isa        => 'ArrayRef',
                                                   is         => 'ro'
                                                  )
                                          );
    my $attr2 = $attr->clone_and_inherit_options( isa => 'Int');

    my $exception = exception {
        $attr2->get_value($class);
    };

    like(
        $exception,
        qr/Can not auto de-reference the type constraint 'Int'/,
        "Cannot auto-deref with 'Int'");

    isa_ok(
        $exception,
        "Moose::Exception::CannotAutoDereferenceTypeConstraint",
        "Cannot auto-deref with 'Int'");

    is(
        $exception->attribute->name,
        "foo",
        "Cannot auto-deref with 'Int'");

    is(
        $exception->type_name,
        "Int",
        "Cannot auto-deref with 'Int'");
}

{
    {
        my $parameterizable = subtype 'ParameterizableArrayRef', as 'ArrayRef';
        my $int = find_type_constraint('Int');
        my $from_parameterizable = $parameterizable->parameterize($int);

        {
            package Parameterizable;
            use Moose;

            has from_parameterizable => ( is => 'rw', isa => $from_parameterizable );
        }
    }

    my $params = Parameterizable->new();
    my $exception = exception {
        $params->from_parameterizable( 'Hello' );
    };

    like(
        $exception,
        qr/\QAttribute (from_parameterizable) does not pass the type constraint because: Validation failed for 'ParameterizableArrayRef[Int]'\E with value "?Hello"?/,
        "'Hello' is a Str");

    isa_ok(
        $exception,
        "Moose::Exception::ValidationFailedForInlineTypeConstraint",
        "'Hello' is a Str");

    is(
        $exception->class_name,
        "Parameterizable",
        "'Hello' is a Str");

    is(
        $exception->value,
        "Hello",
        "'Hello' is a Str");

    is(
        $exception->attribute_name,
        "from_parameterizable",
        "'Hello' is a Str");
}

{
    {
        package Test::LazyBuild::Attribute;
        use Moose;

        has 'fool' => ( lazy_build => 1, is => 'ro');
    }

    my $instance = Test::LazyBuild::Attribute->new;

    my $exception = exception {
        $instance->fool;
    };

    like(
        $exception,
        qr/\QTest::LazyBuild::Attribute does not support builder method '_build_fool' for attribute 'fool' /,
        "builder method _build_fool doesn't exist");

    isa_ok(
        $exception,
        "Moose::Exception::BuilderMethodNotSupportedForInlineAttribute",
        "builder method _build_fool doesn't exist");

    is(
        $exception->attribute_name,
        "fool",
        "builder method _build_fool doesn't exist");

    is(
        $exception->builder,
        "_build_fool",
        "builder method _build_fool doesn't exist");

    is(
        $exception->class_name,
        "Test::LazyBuild::Attribute",
        "builder method _build_fool doesn't exist");
}

{
    {
        package Foo::Required;
        use Moose;

        has 'foo_required' => (
            reader   => 'get_foo_required',
            writer   => 'set_foo_required',
            required => 1,
        );
    }

    my $foo = Foo::Required->new(foo_required => "required");

    my $exception = exception {
        $foo->set_foo_required();
    };

    like(
        $exception,
        qr/\QAttribute (foo_required) is required/,
        "passing no value to set_foo_required");

    isa_ok(
        $exception,
        "Moose::Exception::AttributeIsRequired",
        "passing no value to set_foo_required");

    is(
        $exception->attribute_name,
        'foo_required',
        "passing no value to set_foo_required");

    isa_ok(
        $exception->class_name,
        'Foo::Required',
        "passing no value to set_foo_required");
}

{
    use Moose::Util::TypeConstraints;

    my $exception = exception {
        {
            package BadMetaClass;
            use Moose;

            has 'foo' => (
                is      => 'ro',
                isa     => "Moose::Util::TypeConstraints",
                handles => qr/hello/
            );
        }
    };

    like(
        $exception,
        qr/Unable to recognize the delegate metaclass 'Class::MOP::Package/,
        "unable to recognize metaclass of Moose::Util::TypeConstraints");

    isa_ok(
        $exception,
        "Moose::Exception::UnableToRecognizeDelegateMetaclass",
        "unable to recognize metaclass of Moose::Util::TypeConstraints");

    is(
        $exception->attribute->name,
        'foo',
        "unable to recognize metaclass of Moose::Util::TypeConstraints");

    is(
        $exception->delegate_metaclass->name,
        'Moose::Util::TypeConstraints',
        "unable to recognize metaclass of Moose::Util::TypeConstraints");
}

{
    my $exception = exception {
        package Foo::CannotCoerce::WithoutCoercion;
        use Moose;

        has 'foo' => (
            is     => 'ro',
            isa    => 'Str',
            coerce => 1
        )
    };

    like(
        $exception,
        qr/\QYou cannot coerce an attribute (foo) unless its type (Str) has a coercion/,
        "has throws error with odd number of attribute options");

    isa_ok(
        $exception,
        "Moose::Exception::CannotCoerceAttributeWhichHasNoCoercion",
        "has throws error with odd number of attribute options");

    is(
        $exception->attribute_name,
        'foo',
        "has throws error with odd number of attribute options");

    is(
        $exception->type_name,
        'Str',
        "has throws error with odd number of attribute options");
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
        qr/\QYou must pass an even number of attribute options/,
        'has throws exception with odd number of attribute options');

    isa_ok(
        $exception,
        "Moose::Exception::MustPassEvenNumberOfAttributeOptions",
        'has throws exception with odd number of attribute options');

    is(
        $exception->attribute_name,
        'bar',
        'has throws exception with odd number of attribute options');
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
        qr/^Attribute \(bar\) does not pass the type constraint because: Validation failed for 'Int' with value "?test"?/,
        "bar is an 'Int' and 'Str' is given");
        #Attribute (bar) does not pass the type constraint because: Validation failed for 'Int' with value "test"

    isa_ok(
        $exception,
        "Moose::Exception::ValidationFailedForTypeConstraint",
        "bar is an 'Int' and 'Str' is given");
}

done_testing;
