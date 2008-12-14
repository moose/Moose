#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;

{
    package My::Attribute::Trait;
    use Moose::Role;

    sub reversed_name {
        my $self = shift;
        scalar reverse $self->name;
    }
}

{
    package My::Class;
    use Moose;

    has foo => (
        traits => [
            'My::Attribute::Trait' => {
                alias => {
                    reversed_name => 'eman',
                },
            },
        ],
    );

}

my $attr = My::Class->meta->get_attribute('foo');
is($attr->eman, 'oof', 'the aliased method is in the attribute');
ok(!$attr->can('reversed_name'), 'the method was not installed under its original name');

