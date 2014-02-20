
use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose::Util::TypeConstraints;

{
    my $t = find_type_constraint('ArrayRef');
    my $intType = find_type_constraint("Int");
    my $type = Moose::Meta::TypeConstraint::Parameterizable->new( name => 'xyz', parent => $t);

    my $exception = exception {
        $type->generate_inline_for( $intType, '$_[0]');
    };

    like(
        $exception,
        qr/Can't generate an inline constraint for Int, since none was defined/,
        "no inline constraint was defined for xyz");

    isa_ok(
        $exception,
        "Moose::Exception::CannotGenerateInlineConstraint",
        "no inline constraint was defined for xyz");

    is(
        $exception->type_name,
        "Int",
        "no inline constraint was defined for xyz");

    is(
        $exception->parameterizable_type_object_name,
        $type->name,
        "no inline constraint was defined for xyz");
}

{
    my $parameterizable = subtype 'parameterizable_arrayref', as 'ArrayRef[Float]';
    my $int = find_type_constraint('Int');
    my $exception = exception {
        my $from_parameterizable = $parameterizable->parameterize("Int");
    };

    like(
        $exception,
        qr/Int is not a subtype of Float/,
        "Int is not a subtype of Float");

    isa_ok(
        $exception,
        "Moose::Exception::ParameterIsNotSubtypeOfParent",
        "Int is not a subtype of Float");

    is(
        $exception->type_name,
        $parameterizable,
        "Int is not a subtype of Float");

    is(
        $exception->type_parameter,
        $int,
        "Int is not a subtype of Float");
}

done_testing;
