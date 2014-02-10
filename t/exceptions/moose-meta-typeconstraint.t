
use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose::Util::TypeConstraints;
use Moose();

# tests for type coercions
{
    subtype 'HexNum' => as 'Int', where { /[a-f0-9]/i };
    my $type_object = find_type_constraint 'HexNum';

    my $exception = exception {
        $type_object->coerce;
    };

    like(
        $exception,
        qr/Cannot coerce without a type coercion/,
        "You cannot coerce a type unless coercion is supported by that type");

    is(
        $exception->type_name,
        'HexNum',
        "You cannot coerce a type unless coercion is supported by that type");

    isa_ok(
        $exception,
        "Moose::Exception::CoercingWithoutCoercions",
        "You cannot coerce a type unless coercion is supported by that type");
}

{
    my $exception = exception {
        Moose::Meta::TypeConstraint->new( message => "foo");
    };

    like(
        $exception,
        qr/The 'message' parameter must be a coderef/,
        "'foo' is not a CODE ref");

    isa_ok(
        $exception,
        "Moose::Exception::MessageParameterMustBeCodeRef",
        "'foo' is not a CODE ref");
}

{
    subtype 'NotInlinable',
        as 'Str',
        where { $_ !~ /Q/ };
    my $not_inlinable = find_type_constraint('NotInlinable');

    my $exception = exception {
        $not_inlinable->_inline_check('$foo');
    };

    like(
        $exception,
        qr/Cannot inline a type constraint check for NotInlinable/,
        "cannot inline NotInlinable");

    isa_ok(
        $exception,
        "Moose::Exception::CannotInlineTypeConstraintCheck",
        "cannot inline NotInlinable");

    is(
        $exception->type_name,
        "NotInlinable",
        "cannot inline NotInlinable");

    is(
        find_type_constraint( $exception->type_name ),
        $not_inlinable,
        "cannot inline NotInlinable");
}

{
    my $exception = exception {
        Moose::Meta::TypeConstraint->new(name => "FooTypeConstraint", constraint => undef)
    };

    like(
        $exception,
        qr/Could not compile type constraint 'FooTypeConstraint' because no constraint check/,
        "constraint is set to undef");

    isa_ok(
        $exception,
        "Moose::Exception::NoConstraintCheckForTypeConstraint",
        "constraint is set to undef");

    is(
        $exception->type_name,
        "FooTypeConstraint",
        "constraint is set to undef");
}

{
    subtype 'OnlyPositiveInts',
        as 'Int',
        where { $_ > 1 };
    my $onlyposint = find_type_constraint('OnlyPositiveInts');

    my $exception = exception {
        $onlyposint->assert_valid( -123 );
    };

    like(
        $exception,
        qr/Validation failed for 'OnlyPositiveInts' with value -123/,
        "-123 is not valid for OnlyPositiveInts");

    isa_ok(
        $exception,
        "Moose::Exception::ValidationFailedForTypeConstraint",
        "-123 is not valid for OnlyPositiveInts");

    is(
        $exception->type->name,
        "OnlyPositiveInts",
        "-123 is not valid for OnlyPositiveInts");

    is(
        $exception->type,
        $onlyposint,
        "-123 is not valid for OnlyPositiveInts");

    is(
        $exception->value,
        -123,
        "-123 is not valid for OnlyPositiveInts");
}

done_testing;
