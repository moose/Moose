#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;
use Moose::Meta::Class;
use Moose::Util;

use lib 't/lib', 'lib';

use Role::Child;

_test('Role::Parent', 'meth1,meth2');
_test('Role::Child', 'aliased_meth1,meth1,meth2');

sub _test {
    my ($role, $methods) = @_;
    is join(',', sort $role->meta->get_method_list), $methods;
}

