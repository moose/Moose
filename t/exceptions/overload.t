use strict;
use warnings;

use Test::More 0.96;
use Moose::Exception;

subtest 'regular string messages' => sub
{
    my $exception = Moose::Exception->new(message => 'barf!');

    like($exception, qr/barf/, 'stringification for regex works');

    ok($exception ne 'oh hai', 'direct string comparison works');

    ok($exception, 'exception can be treated as a boolean');
};

{
    package MyException;
    sub new {
        my ($class, $message) = @_;
        bless \$message;
    }
    use overload(
        q{""}    => sub { ${$_[0]} },
        fallback => 1,
    );
}

subtest 'message objects' => sub
{
    my $message = MyException->new('barf!');
    is(ref($message), 'MyException', 'exception message is an object');
    is($message, 'barf!', '...which stringifies to the message string');

    my $exception = Moose::Exception->new(message => $message);

    like($exception, qr/barf/, 'stringification for regex works');

    ok($exception ne 'oh hai', 'direct string comparison works');

    ok($exception, 'exception can be treated as a boolean');
};

done_testing;
