
# as discussed on irc between ether and t0m
# <@ether> t0m: it's known. I asked doy about this a day or two ago as well
# <@ether> the problem is that the requires() is evaluated immediately, but
#          the attributes are not added until the final composition into
#          the class
# <@ether> I suppose the solution would be to compose the attributes into
#          the "thing" that results from TesT::Role::ProvidesThing
#          composing RequiresThing, rather than it being delayed until the
#          final composition, but I suspect that requires a lot of heavy
#          work in the core
# <@ether> it's frustrating because it pretty much means you can't put a
#          'requires' statement in anything but a class
# <@ether> so you can't compose a role built from other roles in order to
#          build an interface, and guarantee that interface was built
#          correctly with the requires() assertions

use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;
use Test::NoWarnings;

{
    package Test::Role::RequiresThing;
    use Moose::Role;

    requires 'thing';
}
{
    package Test::Role::ProvidesThing;
    use Moose::Role;

    has thing => ( is => 'ro' );

    with 'Test::Role::RequiresThing';
}

{
    package Test::Class;
    use Moose;

    lives_ok { with 'Test::Role::ProvidesThing' } 'can compose role that imposes a requirement that a composed role satisfies';
}

