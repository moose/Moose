#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 15;

BEGIN {
    use_ok('Moose');           
}

{
	package Point;
	use Moose;
	
	has '$.x' => (reader   => 'x');
	has '$.y' => (accessor => 'y');
	
	sub clear {
	    my $self = shift;
	    $self->{'$.x'} = 0;
	    $self->y(0);    
	}
	
	package Point3D;
	use Moose;
	
	use base 'Point';
	
	has '$:z';
	
	sub clear {
	    my $self = shift;
		$self->SUPER::clear();
	    $self->{'$:z'} = 0;
	}
	
}

my $point = Point->new(x => 1, y => 2);	
isa_ok($point, 'Point');

is($point->x, 1, '... got the right value for x');
is($point->y, 2, '... got the right value for y');

$point->y(10);

is($point->y, 10, '... got the right (changed) value for y');

$point->clear();

is($point->x, 0, '... got the right (cleared) value for x');
is($point->y, 0, '... got the right (cleared) value for y');

my $point3d = Point3D->new(x => 10, y => 15, z => 3);
isa_ok($point3d, 'Point3D');
isa_ok($point3d, 'Point');

is($point3d->x, 10, '... got the right value for x');
is($point3d->y, 15, '... got the right value for y');
is($point3d->{'$:z'}, 3, '... got the right value for z');

$point3d->clear();

is($point3d->x, 0, '... got the right (cleared) value for x');
is($point3d->y, 0, '... got the right (cleared) value for y');
is($point3d->{'$:z'}, 0, '... got the right (cleared) value for z');
