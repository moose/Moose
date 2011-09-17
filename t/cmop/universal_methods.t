use strict;
use warnings;

use Test::More;
use Class::MOP;

my $meta_class = Class::MOP::Class->create_anon_class;

my @universal_methods = qw/isa can VERSION/;
push @universal_methods, 'DOES' if $] >= 5.010;

TODO: {
    for my $method ( @universal_methods ) {
        ok $meta_class->find_method_by_name($method), "has UNIVERSAL method $method";
    }
};

done_testing;
