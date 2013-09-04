use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Moose ();

use lib 't/lib';

{
    package t::bugs::Bar;
    use Moose;

    # empty class.

    no Moose;
    __PACKAGE__->meta->make_immutable();

    1;
}

my $meta;
use Data::Dumper;
isnt ( exception {
    $meta = Moose::Meta::Class->create_anon_class(
        superclasses => [ 't::bugs::Bar', ], # any old class will work
        roles        => [ 'Role::BreakOnLoad', ],
    )
}, undef, 'Class dies when attempting composition');

my $except;
isnt ( $except = exception {
    $meta = Moose::Meta::Class->create_anon_class(
        superclasses => [ 't::bugs::Bar', ],
        roles        => [ 'Role::BreakOnLoad', ],
    );
}, undef, 'Class continues to die when attempting composition');

done_testing;
