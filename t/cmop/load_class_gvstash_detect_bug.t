use strict;
use warnings;

use FindBin;
use File::Spec::Functions;

use Test::More;
use Test::Fatal;

use Class::MOP;

use lib catdir($FindBin::Bin, 'lib');

is( exception {
    Class::MOP::load_class('TestClassLoaded::Sub');
}, undef );

TestClassLoaded->can('a_method');

is( exception {
    Class::MOP::load_class('TestClassLoaded');
}, undef );

is( exception {
    TestClassLoaded->a_method;
}, undef );

done_testing;
