#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

BEGIN {
    use_ok('Moose');
}

{
    package Eq;
    use strict;
    use warnings;
    use Moose::Role;
    
    requires 'equal';
    
    sub not_equal { 
        my ($self, $other) = @_;
        !$self->equal($other);
    }    
}

isa_ok(Eq->meta, 'Moose::Meta::Role');
ok(Eq->isa('Moose::Role::Base'), '... Eq is a role');

is_deeply(
    Eq->meta->requires,
    [ 'equal' ],
    '... got the right required method');
    
is_deeply(
    [ sort Eq->meta->get_method_list ],
    [ 'not_equal' ],
    '... got the right method list');    
    
