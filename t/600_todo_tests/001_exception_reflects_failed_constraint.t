#!/usr/bin/perl

# In the case where a child type constraint's parent constraint fails,
# the exception should reference the parent type constraint that actually
# failed instead of always referencing the child'd type constraint

use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    use_ok('Moose::Util::TypeConstraints');
}

lives_ok {
    subtype 'ParentConstraint' => as 'Str' => where {0};
} 'specified parent type constraint';

my $tc;
lives_ok {
    $tc = subtype 'ChildConstraint' => as 'ParentConstraint' => where {1};
} 'specified child type constraint';

{
    my $errmsg = $tc->validate();

    TODO: {
        local $TODO = 'Not yet supported';
        ok($errmsg !~ /Validation failed for 'ChildConstraint'/, 'exception references failing parent constraint');
    };
}

done_testing;
