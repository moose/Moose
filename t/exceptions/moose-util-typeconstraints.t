
use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose::Util::TypeConstraints;

my $x = "123";

{
    my $default = [1, 2, 3];
    my $exception = exception {
        match_on_type $x => ( 'Int' =>
                               sub { "Action for Int"; } =>
                               $default
        );
    };

    like(
        $exception,
        qr/\QDefault case must be a CODE ref, not $default/,
        "an ArrayRef is passed as a default");
        #Default case must be a CODE ref, not ARRAY(0x14f6fc8)

    isa_ok(
        $exception,
        'Moose::Exception::DefaultToMatchOnTypeMustBeCodeRef',
        "an ArrayRef is passed as a default");

    is(
        $exception->default_action,
        $default,
        "an ArrayRef is passed as a default");

    is(
        $exception->to_match,
        $x,
        "an ArrayRef is passed as a default");
}

{
    my $exception = exception {
        match_on_type $x => ( 'doesNotExist' => sub { "Action for Int"; } );
    };

    like(
        $exception,
        qr/\QCannot find or parse the type 'doesNotExist'/,
        "doesNotExist is not a valid type");

    isa_ok(
        $exception,
        'Moose::Exception::CannotFindTypeGivenToMatchOnType',
        "doesNotExist is not a valid type");

    is(
        $exception->type,
        "doesNotExist",
        "doesNotExist is not a valid type");

    is(
        $exception->to_match,
        $x,
        "doesNotExist is not a valid type");
}

{
    my $action = [1, 2, 3];
    my $exception = exception {
        match_on_type $x => ( Int => $action );
    };

    like(
        $exception,
        qr/\QMatch action must be a CODE ref, not $action/,
        "an ArrayRef is given as action");
        #Match action must be a CODE ref, not ARRAY(0x27a0748)

    isa_ok(
        $exception,
        'Moose::Exception::MatchActionMustBeACodeRef',
        "an ArrayRef is given as action");

    is(
        $exception->type_name,
        "Int",
        "an ArrayRef is given as action");

    is(
        $exception->to_match,
        $x,
        "an ArrayRef is given as action");

    is(
        $exception->action,
        $action,
        "an ArrayRef is given as action");
}

{
    my $exception = exception {
        match_on_type $x => ( 'ArrayRef' => sub { "Action for Int"; } );
    };

    like(
        $exception,
        qr/\QNo cases matched for $x/,
        "$x is not an ArrayRef");
        #No cases matched for 123

    isa_ok(
        $exception,
        'Moose::Exception::NoCasesMatched',
        "$x is not an ArrayRef");

    is(
        $exception->to_match,
        $x,
        "$x is not an ArrayRef");
}

{
    {
        package TestType;
        use Moose;
        extends 'Moose::Meta::TypeConstraint';

        sub name {
            undef;
        }
    }

    my $tt = TestType->new;
    my $exception = exception {
        register_type_constraint( $tt );
    };

    like(
        $exception,
        qr/can't register an unnamed type constraint/,
        "name has been set to undef for TestType");

    isa_ok(
        $exception,
        'Moose::Exception::CannotRegisterUnnamedTypeConstraint',
        "name has been set to undef for TestType");
}

{
    my $exception = exception {
        union 'StrUndef', 'Str | Undef |';
    };

    like(
        $exception,
        qr/\Q'Str | Undef |' didn't parse (parse-pos=11 and str-length=13)/,
        "cannot parse 'Str| Undef |'");

    isa_ok(
        $exception,
        'Moose::Exception::CouldNotParseType',
        "cannot parse 'Str| Undef |'");

    is(
        $exception->type,
        'Str | Undef |',
        "cannot parse 'Str| Undef |'");
}

done_testing;
