package MyMooseA;

use Moose;

has 'b' => (is => 'rw', isa => 'MyMooseB');

no Moose;

1;
