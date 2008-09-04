#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

my ($around_new);
{
    package Foo;
    use Moose;

    around new => sub { my $o = shift; $around_new = 1; $o->(@_); };
    has 'foo' => (is => 'rw', isa => 'Int');

    package Bar;
    use Moose;
    extends 'Foo';
    Bar->meta->make_immutable;
}

my $orig_new = Foo->meta->find_method_by_name('new');
isa_ok($orig_new, 'Class::MOP::Method::Wrapped');
$orig_new = $orig_new->get_original_method;
isa_ok($orig_new, 'Moose::Meta::Method');

Foo->meta->make_immutable(debug => 0);
my $inlined_new = Foo->meta->find_method_by_name('new');
isa_ok($inlined_new, 'Class::MOP::Method::Wrapped');
$inlined_new = $inlined_new->get_original_method;

TODO:
{
    local $TODO = 'but it isa Moose::Meta::Method instead';
    isa_ok($inlined_new, 'Moose::Meta::Method::Constructor');
}

Foo->new(foo => 100);
ok($around_new, 'around new called');

$around_new = 0;
Bar->new(foo => 100);

TODO:
{
    local $TODO = 'but it is not called';
    ok($around_new, 'around new called');
}
