package Demolition::OnceRemoved;
use strict;
use warnings;
use Demolition::Demolisher;

# This variable is only in scope during the initial `use`
# As it leaves scope, Perl will call DESTROY on it
# (and Moose::Object will then go through its DEMOLISHALL method)
my $d = Demolition::Demolisher->new;

1;
