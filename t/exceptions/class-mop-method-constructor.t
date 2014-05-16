use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose();

{
    my $exception = exception {
        Class::MOP::Method::Constructor->new( is_inline => 1);
    };

    like(
        $exception,
        qr/\QYou must pass a metaclass instance if you want to inline/,
        "no metaclass is given");

    isa_ok(
        $exception,
        "Moose::Exception::MustSupplyAMetaclass",
        "no metaclass is given");
}

{
    my $exception = exception {
        Class::MOP::Method::Constructor->new;
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
    BEGIN
    {
        {
            package NewMetaClass;
            use Moose;
            extends 'Moose::Meta::Class';

            sub _inline_new_object {
                return 'print "xyz'; # this is a intentional syntax error,
            }
        }
    };

    {
        package BadConstructorClass;
        use Moose -metaclass => 'NewMetaClass';
    }

    my $exception = exception {
        BadConstructorClass->meta->make_immutable();
    };

    like(
        $exception,
        qr/Could not eval the constructor :/,
        "syntax error in _inline_new_object");

    isa_ok(
        $exception,
        "Moose::Exception::CouldNotEvalConstructor",
        "syntax error in _inline_new_object");
}

done_testing;
