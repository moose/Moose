
package Bar;
use strict;
use warnings;
use Moose;

type Baz => where { 1 };

subtype Bling => as Baz => where { 1 };

1;