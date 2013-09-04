use strict;
use warnings;

use Test::More;
use Test::Exception;

use Moose::Meta::Class;

use lib 't/lib/Role', 't/lib', 'lib';

{
    package t::bugs::Bar;
    use Moose;

    # empty class.

    no Moose;
    __PACKAGE__->meta->make_immutable();

    1;
}

my $meta;
dies_ok
    {
        $meta = Moose::Meta::Class->create_anon_class(
            superclasses => [ 't::bugs::Bar', ], # any old class will work
            roles        => [ 'Role::BreakOnLoad', ],
        )
    }
    'Class dies when attempting composition';

# this is the failing issue. it should die, not live, as we know the role
# is bad.
dies_ok
    {
        $meta = Moose::Meta::Class->create_anon_class(
            superclasses => [ 't::bugs::Bar', ],
            roles        => [ 'Role::BreakOnLoad', ],
        );
    }
    'Class continues to die when attempting composition';


done_testing;
