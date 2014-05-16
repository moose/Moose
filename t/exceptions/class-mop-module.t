use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose();

{
    my $exception = exception {
        Class::MOP::Module->create_anon(cache => 1);
    };

    like(
        $exception,
        qr/Modules are not cacheable/,
        "can't cache anon packages");

    isa_ok(
        $exception,
        "Moose::Exception::PackagesAndModulesAreNotCachable",
        "can't cache anon packages");
}

done_testing;
