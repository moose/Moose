#!/usr/bin/perl

use strict;
use warnings;
use Test::More;


{
    package Bar::Meta::Attribute;
    use Moose;

    extends 'Moose::Meta::Attribute';

    has 'my_legal_option' => (
      isa => 'CodeRef',
      is => 'rw',
    );

    around legal_options_for_inheritance => sub {
      return (shift->(@_), qw/my_legal_option/);
    };

    package Bar;
    use Moose;

    has 'bar' => (
      metaclass       => 'Bar::Meta::Attribute',
      my_legal_option => sub { 'Bar' },
      is => 'bare',
    );

    package Bar::B;
    use Moose;

    extends 'Bar';

    has '+bar' => (
      my_legal_option => sub { 'Bar::B' }
    );
}

my $bar_attr = Bar::B->meta->get_attribute('bar');
my ($legal_option) = grep {
  $_ eq 'my_legal_option'
} $bar_attr->legal_options_for_inheritance;
is($legal_option, 'my_legal_option',
  '... added my_legal_option as legal option for inheritance' );
is($bar_attr->my_legal_option->(), 'Bar::B', '... overloaded my_legal_option');

done_testing;
