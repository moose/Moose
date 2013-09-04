use strict;
use warnings;

use Test::More;
use Test::Fatal qw{dies_ok};
use Moose ();

use lib 't/lib/Role';

{
    package t::bugs::Bar;
    use Moose;

    # empty class.

    no Moose;
    __PACKAGE__->meta->make_immutable();

    1;
}

TODO:
{
    local $TODO = "The second create_anon_class should die in the same way
        the first create_anon_class dies.";

    my $meta;
    dies_ok
        {
            $meta = Moose::Meta::Class->create_anon_class(
                superclasses => [ 't::bugs::Bar', ], # any old class will work
                roles        => [ 'Role::BreakOnLoad', ],
            )
        }
        'Class dies when attempting composition';

        {
            $meta = Moose::Meta::Class->create_anon_class(
                superclasses => [ 't::bugs::Bar', ],
                roles        => [ 'Role::BreakOnLoad', ],
            );
        }
        'Class continues to die when attempting composition';
}

done_testing;
