#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

my ($around_new);
{
    package Foo;
    use Moose;

    around new => sub { my $o = shift; $around_new = 1; $o->(@_); };
    has 'foo' => (is => 'rw', isa => 'Int');
}

my $orig_new = Foo->meta->find_method_by_name('new');
isa_ok($orig_new, 'Class::MOP::Method::Wrapped');
$orig_new = $orig_new->get_original_method;
isa_ok($orig_new, 'Moose::Meta::Method');

Foo->meta->make_immutable(debug => 0);
my $inlined_new = Foo->meta->find_method_by_name('new');
isa_ok($inlined_new, 'Class::MOP::Method::Wrapped');
$inlined_new = $inlined_new->get_original_method;
isa_ok($inlined_new, 'Moose::Meta::Method::Constructor');

my $foo = Foo->new(foo => 100);
ok($around_new, 'around new called');

