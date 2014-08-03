use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    package NonHashref;
    sub new { bless [], shift }
}

# Note that we don't need to test the immutable case since this package will
# not inline a constructor - it'll warn that the parent is not a subclass of
# Moose::Object.
{
    package NonHashref::Subclassed;
    use Moose;
    extends 'NonHashref';
    has thing => ( is => 'rw', default => sub {1} );
}

like(
    exception { NonHashref::Subclassed->new()->thing() },
    qr/Constructor of parent class of NonHashref::Subclassed returned an object based on ARRAY.*extends-non-moo/,
    'non-hashref constructor in parent class results in useful error message'
);

like(
    exception { NonHashref::Subclassed->new()->thing() },
    qr/Constructor of parent class of NonHashref::Subclassed returned an object based on ARRAY.*extends-non-moo/,
    'non-hashref constructor in parent class results in useful error message'
);
