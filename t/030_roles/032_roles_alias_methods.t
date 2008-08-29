#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;
use Moose::Meta::Class;
use Moose::Util;

use lib 't/lib', 'lib';

use Role::Child;


is_deeply(
    [ sort Role::Parent->meta->get_method_list ],
    [qw( meth1 meth2 )],
    'method list for Role::Parent'
);
is_deeply(
    [ sort Role::Child->meta->get_method_list ],
    [qw( aliased_meth1 meth1 meth2 )],
    'method list for Role::Child'
);
