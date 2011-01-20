#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Moose::Exporter;

my $attributes_applied = 0;

{
    
    package MyMoose;
    use Moose;
    
    Moose::Exporter->setup_import_methods(
                  role_metaroles => {
                      application_to_class =>
                        ['Application'],
                  }, );

    package Application;
    use Moose::Role;

    before apply_attributes => sub {
        $attributes_applied++;
    };

    package RoleA;
    use Moose::Role;
    MyMoose->import;



    has bar => ( is => 'rw', default => 1 );

    package RoleB;
    use Moose::Role;
    MyMoose->import;

    has foo => ( is => 'rw', default => 1 );
}

{

    package ComposeList;

    use Moose;
    use namespace::autoclean;

    with qw( RoleB RoleA );

    __PACKAGE__->meta->make_immutable;
}

is($attributes_applied, 2);

{

    package ComposeSeparate;

    use Moose;
    use namespace::autoclean;

    with 'RoleA';
    with 'RoleB';

    __PACKAGE__->meta->make_immutable;
}

is($attributes_applied, 4);

done_testing;
