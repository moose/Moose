#!/usr/bin/env perl
use strict;
use warnings;
use Test::More skip_all => "Feature not implemented yet";
#use Test::More tests => 1;

{
    package My::Trait;
    use Moose::Role;

    sub reversed_name {
        my $self = shift;
        scalar reverse $self->name;
    }
}

{
    package My::Class;
    use Moose -traits => [
        'My::Trait' => {
            alias => {
                reversed_name => 'enam',
            },
        },
    ];
}

is(My::Class->meta->enam, 'ssalC::yM', 'parameterized trait applied');

