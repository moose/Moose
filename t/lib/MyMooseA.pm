package MyMooseA;

use strict;
use warnings;
use Moose;

has 'b' => (is => 'rw', isa => 'MyMooseB');

1;