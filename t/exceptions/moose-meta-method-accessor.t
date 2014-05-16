use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose();

{
    {
        package Foo;
        use Moose;
        extends 'Moose::Meta::Method::Accessor';
    }

    my $attr = Class::MOP::Attribute->new("bar");
    Foo->meta->add_attribute($attr);

    my $foo;
    my $exception = exception {
        $foo = Foo->new( name          => "new",
                         package_name  => "Foo",
                         is_inline     => 1,
                         attribute     => $attr,
                         accessor_type => "writer"
                       );
    };

    like(
        $exception,
        qr/\QCould not generate inline writer because : Could not create writer for 'bar' because Can't locate object method "_eval_environment" via package "Class::MOP::Attribute"/,
        "cannot generate writer");

    isa_ok(
        $exception->error,
        "Moose::Exception::CouldNotCreateWriter",
        "cannot generate writer");

    isa_ok(
        $exception,
        "Moose::Exception::CouldNotGenerateInlineAttributeMethod",
        "cannot generate writer");

    is(
        $exception->error->attribute_name,
        'bar',
        "cannot generate writer");

    is(
        ref($exception->error->instance),
        "Foo",
        "cannot generate writer");
}

done_testing;
