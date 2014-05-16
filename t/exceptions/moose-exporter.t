use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    my $exception = exception {
        package MooseX::NoAlso;
        use Moose ();

        Moose::Exporter->setup_import_methods(
            also => ['NoSuchThing']
        );
    };

    like(
        $exception,
        qr/\QPackage in also (NoSuchThing) does not seem to use Moose::Exporter (is it loaded?)/,
        'a package which does not use Moose::Exporter in also dies with an error');

    isa_ok(
        $exception,
        'Moose::Exception::PackageDoesNotUseMooseExporter',
        'a package which does not use Moose::Exporter in also dies with an error');

    is(
        $exception->package,
        "NoSuchThing",
        'a package which does not use Moose::Exporter in also dies with an error');
}

{
    my $exception = exception {
        {
            package MooseX::CircularAlso;
            use Moose;

            Moose::Exporter->setup_import_methods(
                also => [ 'Moose', 'MooseX::CircularAlso' ],
            );
        }
    };

    like(
        $exception,
        qr/\QCircular reference in 'also' parameter to Moose::Exporter between MooseX::CircularAlso and MooseX::CircularAlso/,
        'a circular reference in also dies with an error');

    isa_ok(
        $exception,
        'Moose::Exception::CircularReferenceInAlso',
        'a circular reference in also dies with an error');

    is(
        $exception->also_parameter,
        "MooseX::CircularAlso",
        'a circular reference in also dies with an error');
}

{
    {
        package My::SimpleTrait;
        use Moose::Role;

        sub simple { return 5 }
    }

    use Moose::Util::TypeConstraints;
    my $exception = exception {
            Moose::Util::TypeConstraints->import(
                -traits => 'My::SimpleTrait' );
    };

    like(
        $exception,
        qr/\QCannot provide traits when Moose::Util::TypeConstraints does not have an init_meta() method/,
        'cannot provide -traits to an exporting module that does not init_meta');

    isa_ok(
        $exception,
        "Moose::Exception::ClassDoesNotHaveInitMeta",
        'cannot provide -traits to an exporting module that does not init_meta');

    is(
        $exception->class_name,
        "Moose::Util::TypeConstraints",
        'cannot provide -traits to an exporting module that does not init_meta');
}

{
    my $exception = exception {
        {
            package MooseX::BadTraits;
            use Moose ();

            Moose::Exporter->setup_import_methods(
                trait_aliases => [{hello => 1}]
            );
        }
    };

    like(
        $exception,
        qr/HASH references are not valid arguments to the 'trait_aliases' option/,
        "a HASH ref is given to trait_aliases");

    isa_ok(
        $exception,
        "Moose::Exception::InvalidArgumentsToTraitAliases",
        "a HASH ref is given to trait_aliases");

    is(
        $exception->package_name,
        "MooseX::BadTraits",
        "a HASH ref is given to trait_aliases");
}

done_testing;
