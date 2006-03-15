#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;

BEGIN {
    use_ok('Moose');           
}

{
	package Elk;
	use strict;
	use warnings;
	
	sub new {
		my $class = shift;
		bless { no_moose => "Elk" } => $class;
	}
	
	sub no_moose { $_[0]->{no_moose} }

	package Foo::Moose;
	use strict;
	use warnings;	
	use Moose;
	
	extends 'Elk';
	
	has 'moose' => (is => 'ro', default => 'Foo');
	
	sub new {
		my $class = shift;
		my $super = $class->SUPER::new(@_);
		return $class->meta->new_object('__INSTANCE__' => $super, @_);
	}
}

my $foo_moose = Foo::Moose->new();
isa_ok($foo_moose, 'Foo::Moose');
isa_ok($foo_moose, 'Elk');

is($foo_moose->no_moose, 'Elk', '... got the right value from the Elk method');
is($foo_moose->moose, 'Foo', '... got the right value from the Foo::Moose method');