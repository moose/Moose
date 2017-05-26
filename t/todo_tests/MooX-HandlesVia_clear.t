use strict;
use warnings;

use Test::More;

use Test::Requires {
    'Moo::Role'        => '0',
    'MooX::HandlesVia' => '0.001008',
    'Types::Standard'  => '0',
};

eval {
    do {
        # works with Moose 2.1801, fails with Moose 2.1802
        package MyRole {

            use Moo::Role;
            use MooX::HandlesVia;
            use Types::Standard qw/ HashRef Str /;
            has foo => (
                is          => 'ro',
                isa         => HashRef [Str],
                handles_via => 'Hash',
                handles     => { clear_foo => 'clear', },
            );
        }

        package MyClass {
            use Moose;
            with 'MyRole';
        }
    };
};

TODO: {
    local $TODO = 'Fix failing MooX::HandlesVia Hash clear';
    ok !$@, "Used MooX::HandleVia handles => Hash 'clear' successfully";
}

done_testing();

