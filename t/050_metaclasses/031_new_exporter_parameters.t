#!/usr/bin/perl
use strict;
use warnings;
use Test::More skip_all => "not implemented yet";
#use Test::More tests => 4;

my @init_meta_args;

BEGIN {
    package My::Moose;
    use Moose::Exporter;
    use Moose ();

    Moose::Exporter->setup_import_methods(
        with_caller => ['has_rw'],
        also => 'Moose',
        extra_parameters => ['attribute'],
    );

    sub has_rw {
        my $caller = shift;
        my $name   = shift;
        $caller->meta->add_attribute($name, is => 'rw', @_);
    }

    sub init_meta {
        my $self = shift;
        my %args = @_;

        push @init_meta_args, \%args;

        my $attribute = $args{'attribute'};
        my $meta = Moose->init_meta(
            %args,
        );

        if ($attribute) {
            $meta->add_attribute($attribute, is => 'rw');
        }

        return $meta;
    }
}

{
    package My::Moose::User;
    BEGIN { My::Moose->import };

    has_rw 'counter' => (
        isa => 'Int',
    );
}

is_deeply(\@init_meta_args, [
    {
        for_class => 'My::Moose::User',
        metaclass => 'Moose::Meta::Class'
    }
], "attribute wasn't passed in yet");

ok(My::Moose::User->meta->get_attribute('counter')->has_accessor, 'our exported sugar works');

{
    package My::Other::Moose::User;
    BEGIN {
        My::Moose->import(
            attribute => 'counter',
        );
    };
}

is_deeply(\@init_meta_args, [
    {
        for_class => 'My::Other::Moose::User',
        metaclass => 'Moose::Meta::Class'
        attribute => 'counter',
    }
], "got attribute in our init_meta params");


ok(My::Moose::User->meta->get_attribute('counter')->has_accessor, 'our extra exporter option worked');
