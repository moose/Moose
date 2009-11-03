#!/usr/bin/perl

use strict;
use warnings;
use Test::More;



{
    package Bar::Meta::Attribute;
    use Moose;

    extends 'Moose::Meta::Attribute';

    has 'my_illegal_option' => (
      isa => 'CodeRef',
      is => 'rw',
    );

    around illegal_options_for_inheritance => sub {
      return (shift->(@_), qw/my_illegal_option/);
    };

    package Bar;
    use Moose;

    has 'bar' => (
      metaclass       => 'Bar::Meta::Attribute',
      my_illegal_option => sub { 'Bar' },
      is => 'bare',
    );
}

my $bar_attr = Bar->meta->get_attribute('bar');
my ($illegal_option) = grep {
  $_ eq 'my_illegal_option'
} $bar_attr->illegal_options_for_inheritance;
is($illegal_option, 'my_illegal_option',
  '... added my_illegal_option as illegal option for inheritance' );

done_testing;
