#!/usr/bin/perl

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

done_testing;
