use strict;
use warnings;
use Test::More;

{
        package HttpGet;
        use Moose::Role;
        requires 'get';
};

{
        package UserAgent;
        use Moose;
        with qw( HttpGet );
        sub get { 1 };
};

{
        package Spider;
        use Moose;
        has ua => (
                is         => 'ro',
                does       => 'HttpGet',
                handles    => 'HttpGet',
                lazy_build => 1,
        );
        sub _build_ua { UserAgent->new };
};

my $woolly = Spider->new;

# Make sure that the Delegated roles show up

ok( $woolly->DOES('Spider') );
ok( $woolly->DOES('HttpGet') );

done_testing;
