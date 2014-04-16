
use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose::Util 'throw_exception';

{
    package Foo;
    use Moose;

    has 'foo' => (
        is => 'ro'
    );

    has 'bar' => (
        is => 'ro'
    );
}

{
    my $exception = exception {
            throw_exception( LazyAttributeNeedsADefault => attribute_name => "foo",
                                                           attribute      => Foo->meta->get_attribute("bar")
                           );
    };

    like(
        $exception,
        qr/\Qattribute_name (foo) does not match attribute->name (bar)/,
        "you have given attribute_name as 'foo' and attribute->name as 'bar'");

    isa_ok(
        $exception,
        "Moose::Exception::AttributeNamesDoNotMatch",
        "you have given attribute_name as 'foo' and attribute->name as 'bar'");

    is(
        $exception->attribute_name,
        "foo",
        "you have given attribute_name as 'foo' and attribute->name as 'bar'");

    is(
        $exception->attribute->name,
        "bar",
        "you have given attribute_name as 'foo' and attribute->name as 'bar'");
}

{
    my $exception = exception {
        throw_exception("LazyAttributeNeedsADefault");
    };

    like(
        $exception,
        qr/\QYou need to give attribute or attribute_name or both/,
        "please give either attribute or attribute_name");

    isa_ok(
        $exception,
        "Moose::Exception::NeitherAttributeNorAttributeNameIsGiven",
        "please give either attribute or attribute_name");
}

done_testing;
