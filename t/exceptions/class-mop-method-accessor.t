use strict;
use warnings;

use Test::More;
use Test::Moose;
use Test::Fatal;

use Moose();

{
    my $exception = exception {
        Class::MOP::Method::Accessor->new;
    };

    like(
        $exception,
        qr/\QYou must supply an attribute to construct with/,
        "no attribute is given");

    isa_ok(
        $exception,
        "Moose::Exception::MustSupplyAnAttributeToConstructWith",
        "no attribute is given");
}

{
    my $exception = exception {
        Class::MOP::Method::Accessor->new( attribute => "foo" );
    };

    like(
        $exception,
        qr/\QYou must supply an accessor_type to construct with/,
        "no accessor_type is given");

    isa_ok(
        $exception,
        "Moose::Exception::MustSupplyAnAccessorTypeToConstructWith",
        "no accessor_type is given");
}

{
    my $exception = exception {
        Class::MOP::Method::Accessor->new( accessor_type => 'reader', attribute => "foo" );
    };

    like(
        $exception,
        qr/\QYou must supply an attribute which is a 'Class::MOP::Attribute' instance/,
        "attribute isn't an instance of Class::MOP::Attribute");

    isa_ok(
        $exception,
        "Moose::Exception::MustSupplyAClassMOPAttributeInstance",
        "attribute isn't an instance of Class::MOP::Attribute");
}

{
    my $attr = Class::MOP::Attribute->new("Foo", ( is => 'ro'));
    my $exception = exception {
        Class::MOP::Method::Accessor->new( accessor_type => "reader", attribute => $attr);
    };

    like(
        $exception,
        qr/\QYou must supply the package_name and name parameters/,
        "no package_name and name is given");

    isa_ok(
        $exception,
        "Moose::Exception::MustSupplyPackageNameAndName",
        "no package_name and name is given");
}

{
    my $attr = Class::MOP::Attribute->new("foo", ( is => 'ro'));
    my $accessor = Class::MOP::Method::Accessor->new( accessor_type => "reader", attribute => $attr, name => "foo", package_name => "Foo");
    my $exception = exception {
        my $subr = $accessor->_generate_accessor_method_inline();
    };

    like(
        $exception,
        qr/\QCould not generate inline accessor because : Can't call method "get_meta_instance" on an undefined value/,
        "can't call get_meta_instance on an undefined value");

    isa_ok(
        $exception,
        "Moose::Exception::CouldNotGenerateInlineAttributeMethod",
        "can't call get_meta_instance on an undefined value");

    is(
        $exception->option,
        "accessor",
        "can't call get_meta_instance on an undefined value");
}

{
    my $attr = Class::MOP::Attribute->new("foo", ( is => 'ro'));
    my $accessor = Class::MOP::Method::Accessor->new( accessor_type => "reader", attribute => $attr, name => "foo", package_name => "Foo");
    my $exception = exception {
        my $subr = $accessor->_generate_reader_method_inline();
    };

    like(
        $exception,
        qr/\QCould not generate inline reader because : Can't call method "get_meta_instance" on an undefined value/,
        "can't call get_meta_instance on an undefined value");

    isa_ok(
        $exception,
        "Moose::Exception::CouldNotGenerateInlineAttributeMethod",
        "can't call get_meta_instance on an undefined value");

    is(
        $exception->option,
        "reader",
        "can't call get_meta_instance on an undefined value");
}

{
    my $attr = Class::MOP::Attribute->new("foo", ( is => 'ro'));
    my $accessor = Class::MOP::Method::Accessor->new( accessor_type => "reader", attribute => $attr, name => "foo", package_name => "Foo");
    my $exception = exception {
        my $subr = $accessor->_generate_writer_method_inline();
    };

    like(
        $exception,
        qr/\QCould not generate inline writer because : Can't call method "get_meta_instance" on an undefined value/,
        "can't call get_meta_instance on an undefined value");

    isa_ok(
        $exception,
        "Moose::Exception::CouldNotGenerateInlineAttributeMethod",
        "can't call get_meta_instance on an undefined value");

    is(
        $exception->option,
        "writer",
        "can't call get_meta_instance on an undefined value");
}

{
    my $attr = Class::MOP::Attribute->new("foo", ( is => 'ro'));
    my $accessor = Class::MOP::Method::Accessor->new( accessor_type => "reader", attribute => $attr, name => "foo", package_name => "Foo");
    my $exception = exception {
        my $subr = $accessor->_generate_predicate_method_inline();
    };

    like(
        $exception,
        qr/\QCould not generate inline predicate because : Can't call method "get_meta_instance" on an undefined value/,
        "can't call get_meta_instance on an undefined value");

    isa_ok(
        $exception,
        "Moose::Exception::CouldNotGenerateInlineAttributeMethod",
        "can't call get_meta_instance on an undefined value");

    is(
        $exception->option,
        "predicate",
        "can't call get_meta_instance on an undefined value");
}

{
    my $attr = Class::MOP::Attribute->new("foo", ( is => 'ro'));
    my $accessor = Class::MOP::Method::Accessor->new( accessor_type => "reader", attribute => $attr, name => "foo", package_name => "Foo");
    my $exception = exception {
        my $subr = $accessor->_generate_clearer_method_inline();
    };

    like(
        $exception,
        qr/\QCould not generate inline clearer because : Can't call method "get_meta_instance" on an undefined value/,
        "can't call get_meta_instance on an undefined value");

    isa_ok(
        $exception,
        "Moose::Exception::CouldNotGenerateInlineAttributeMethod",
        "can't call get_meta_instance on an undefined value");

    is(
        $exception->option,
        "clearer",
        "can't call get_meta_instance on an undefined value");
}

{
    {
        package Foo::ReadOnlyAccessor;
        use Moose;

        has 'foo' => (
            is       => 'ro',
            isa      => 'Int',
        );
    }

    my $foo = Foo::ReadOnlyAccessor->new;

    my $exception = exception {
        $foo->foo(120);
    };

    like(
        $exception,
        qr/Cannot assign a value to a read-only accessor/,
        "foo is read only");

    isa_ok(
        $exception,
        "Moose::Exception::CannotAssignValueToReadOnlyAccessor",
        "foo is read only");

    is(
        $exception->class_name,
        "Foo::ReadOnlyAccessor",
        "foo is read only");

    is(
        $exception->attribute_name,
        "foo",
        "foo is read only");

    is(
        $exception->value,
        120,
        "foo is read only");
}

{
    {
        package Point;
        use metaclass;

        Point->meta->add_attribute('x' => (
            reader   => 'x',
            init_arg => 'x'
        ));

        sub new {
            my $class = shift;
            bless $class->meta->new_object(@_) => $class;
        }
    }

    my $point = Point->new();

    my $exception = exception {
        $point->x(120);
    };

    like(
        $exception,
        qr/Cannot assign a value to a read-only accessor/,
        "x is read only");

    isa_ok(
        $exception,
        "Moose::Exception::CannotAssignValueToReadOnlyAccessor",
        "x is read only");

    is(
        $exception->class_name,
        "Point",
        "x is read only");

    is(
        $exception->attribute_name,
        "x",
        "x is read only");

    is(
        $exception->value,
        120,
        "x is read only");
}

# we need to test both with and without moose to get full test coverage
# so we can test both the inlined and non inlined version of the generated
# accessor.  This is because Moose always uses the inlined accessor code

{
    {
        package CupOfTea;
        use metaclass;

        CupOfTea->meta->add_attribute('sugars' => (
            reader   => 'sugars',
            writer   => 'set_sugars',
            init_arg => 'sugars'
        ));

        CupOfTea->meta->add_attribute('milk' => (
            reader   => 'milk',
            writer   => '_set_milk',
            init_arg => 'milk'
        ));

        sub new {
            my $class = shift;
            bless $class->meta->new_object(@_) => $class;
        }
    }

    my $cup = CupOfTea->new();
    _test_sugars($cup);
    _test_milk($cup);
}

{
    {
        package CupOfCoffee;
        use Moose;

        has 'sugars' => (
            is       => 'rw',
            writer   => 'set_sugars',
        );

        has 'milk' => (
            is       => 'rw',
            writer   => '_set_milk',
        );
    }

    my $cup = CupOfCoffee->new();
    _test_sugars($cup);
    _test_milk($cup);
}

sub _test_sugars {
    my $cup = shift;

    my $exception = exception { $cup->sugars(2) };
    _test_cup_exception($exception, "sugars", ref($cup), "'set_sugars'");
}

sub _test_milk {
    my $cup = shift;

    my $exception = exception { $cup->milk(2) };
    _test_cup_exception($exception, "milk", ref($cup), "private");
}

sub _test_cup_exception {
    my $exception = shift;
    my $name = shift;
    my $class_name = shift;
    my $writer = shift;

    like(
        $exception,
        qr/\QCannot assign a value to a read-only accessor (did you mean to call the $writer writer?)\E/,
        "$class_name: $name read only");

    isa_ok(
        $exception,
        "Moose::Exception::CannotAssignValueToReadOnlyAccessor",
        "$class_name: $name is read only");

    is(
        $exception->class_name,
        $class_name,
        "$class_name: $name is read only");

    is(
        $exception->attribute_name,
        $name,
        "$class_name: $name is read only");

    is(
        $exception->value,
        2,
        "$class_name: $name is read only");
}

done_testing;
