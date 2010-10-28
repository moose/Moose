use lib "t/lib";
package MyExporter::User;
use MyExporter;

use Test::More;
use Test::Exception;

lives_and {
    with_prototype {
        my $caller = caller(0);
        is($caller, 'MyExporter', "With_caller prototype code gets called from MyMooseX");
    };
} "check function with prototype";

lives_and {
    as_is_prototype {
        my $caller = caller(0);
        is($caller, 'MyExporter', "As-is prototype code gets called from MyMooseX");
    };
} "check function with prototype";

done_testing;
