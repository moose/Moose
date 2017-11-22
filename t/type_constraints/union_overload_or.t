use strict;
use warnings;

use Test::Fatal;
use Test::More;

{

    package Duck;
    use Moose;

    sub quack { }

}

{

    package Swan;
    use Moose;

    sub honk { }

}

{

    package RubberDuck;
    use Moose;

    sub quack { }

}


use Moose::Util::TypeConstraints 'class_type';

my $union = class_type('Duck') | class_type('RubberDuck');

my $duck = Duck->new();
my $rubber_duck = RubberDuck->new();
my $swan = Swan->new();

my @domain_values = ( $duck, $rubber_duck );
is(
    exception { $union->assert_valid($_) },
    undef,
    qq{Union accepts "$_".}
) for @domain_values;

like(
    exception { $union->assert_valid($swan) },
    qr/Validation failed for/,
    qq{Union does not accept Swan.}
);
done_testing;

