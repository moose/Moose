
package Bar;
use strict;
use warnings;
use Moose;
use Moose::Util::TypeConstraints;

type Baz => where { 1 };

subtype Bling => as Baz => where { 1 };

1;