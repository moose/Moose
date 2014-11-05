use strict;
use warnings;

use Moose ();
# Needed to load MarkAsMethods if we're running from a git checkout
BEGIN { $Moose::VERSION ||= 42 }

use Test::More;
use Test::Fatal;
use Test::Requires {
    'MooseX::MarkAsMethods' => 0,
};

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
