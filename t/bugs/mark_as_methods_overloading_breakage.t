use strict;
use warnings;

use Test::More;

BEGIN {
  plan skip_all => 'MooseX::MarkAsMethod is not needed in Moose 2.1400+ and namespace::autoclean 0.16+'
    if eval { +require namespace::autoclean; namespace::autoclean->VERSION('0.16') };
}

use Test::Needs {
    'MooseX::MarkAsMethods' => 0,
};

use Test::Fatal;

{
    package Role2;
    use Moose::Role;
    use MooseX::MarkAsMethods;
    use overload q{""} => '_stringify';
    sub _stringify {ref $_[0]}
}

{
    package Class2;
    use Moose;
    with 'Role2';
}

ok(! exception {
    my $class2 = Class2->new;
    is(
        "$class2",
        'Class2',
        'Class2 got stringification overloading from Role2'
    );
}, 'No error creating a Class2 object');

done_testing;
