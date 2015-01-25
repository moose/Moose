use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    package AttrHasTC;
    use Moose;
    has foo => (
        is  => 'ro',
        isa => 'Int',
    );

    has bar => (
        is  => 'ro',
    );
}

ok(
    AttrHasTC->meta->get_attribute('foo')->verify_against_type_constraint(42),
    'verify_against_type_constraint returns true with valid Int'
);

my $e = exception {
    AttrHasTC->meta->get_attribute('foo')
        ->verify_against_type_constraint('foo');
};

isa_ok(
    $e,
    'Moose::Exception::ValidationFailedForTypeConstraint',
    'exception thrown when verify_against_type_constraint fails'
);

ok(
    AttrHasTC->meta->get_attribute('bar')->verify_against_type_constraint(42),
    'verify_against_type_constraint returns true when attr has no TC'
);

done_testing;
