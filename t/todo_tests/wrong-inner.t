use strict;
use warnings;

use Test::More;

# see RT#89397

{
    package A;
    use Moose;
    sub run {
        my $self = shift;
        inner();
        $self->cleanup;
    }
    sub cleanup {
        inner();
    }
}

{
    package B;
    our $run;
    use Moose;
    extends 'A';
    augment run => sub {
        my $self = shift;
        $run++;
    };
}

B->new->run();

local $TODO = 'wtf is going on here??';
is($B::run, 1, 'B::run is only called once');

done_testing;
