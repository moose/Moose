
package Foo;
use Moose;

has 'bar' => (is => 'rw');

no Moose;

1;
