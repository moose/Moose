use strict;
use warnings;

use Test::More;
use Test::Requires 'Test::LeakTrace';   # skip all if not installed

BEGIN {
    plan skip_all => 'Leak tests fail under Devel::Cover' if $INC{'Devel/Cover.pm'};
}

use Class::MOP;

# 5.10.0 has a bug on weaken($hash_ref) which leaks an AV.
my $expected = ( $] == 5.010_000 ? 1 : 0 );

leaks_cmp_ok {
    Class::MOP::Class->create_anon_class();
}
'<=', $expected, 'create_anon_class()';

leaks_cmp_ok {
    Class::MOP::Class->create_anon_class( superclasses => [qw(Exporter)] );
}
'<=', $expected, 'create_anon_class(superclass => [...])';

done_testing;
