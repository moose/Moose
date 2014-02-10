
use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose();

{
    my $xyz = bless [], "Bar";
    my $class;
    my $exception = exception {
        $class = Class::MOP::Class->create("Foo", (attributes => [$xyz]));
    };

    like(
        $exception,
        qr/\QYour attribute must be an instance of Class::MOP::Mixin::AttributeCore (or a subclass)/,
        "an Array ref blessed into Bar is given to create");

    isa_ok(
        $exception,
        "Moose::Exception::AttributeMustBeAnClassMOPMixinAttributeCoreOrSubclass",
        "an Array ref blessed into Bar is given to create");

    is(
        $exception->attribute,
        $xyz,
        "an Array ref blessed into Bar is given to create");
}

{
    my $class = Class::MOP::Class->create("Foo");
    my $exception = exception {
        $class->has_attribute;
    };

    like(
        $exception,
        qr/You must define an attribute name/,
        "attribute name is not given");

    isa_ok(
        $exception,
        "Moose::Exception::MustDefineAnAttributeName",
        "attribute name is not given");

    is(
	$exception->class_name,
	'Foo',
	"attribute name is not given");
}

{
    my $class = Class::MOP::Class->create("Foo");
    my $exception = exception {
        $class->get_attribute;
    };

    like(
        $exception,
        qr/You must define an attribute name/,
        "attribute name is not given");

    isa_ok(
        $exception,
        "Moose::Exception::MustDefineAnAttributeName",
        "attribute name is not given");

    is(
	$exception->class_name,
	"Foo",
	"attribute name is not given");
}

{
    my $class = Class::MOP::Class->create("Foo");
    my $exception = exception {
        $class->remove_attribute;
    };

    like(
        $exception,
        qr/You must define an attribute name/,
        "attribute name is not given");

    isa_ok(
        $exception,
        "Moose::Exception::MustDefineAnAttributeName",
        "attribute name is not given");

    is(
	$exception->class_name,
	"Foo",
	"attribute name is not given");
}

done_testing;
