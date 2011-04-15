#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use IO::File;
use Moose::Util::TypeConstraints;
use Scalar::Util qw( blessed openhandle );

my $ZERO    = 0;
my $ONE     = 1;
my $INT     = 100;
my $NEG_INT = -100;
my $NUM     = 42.42;
my $NEG_NUM = -42.42;

my $EMPTY_STRING  = q{};
my $STRING        = 'foo';
my $NUM_IN_STRING = 'has 42 in it';
my $INT_WITH_NL1  = "1\n";
my $INT_WITH_NL2  = "\n1";

my $SCALAR_REF     = \( my $var );
my $SCALAR_REF_REF = \$SCALAR_REF;
my $ARRAY_REF      = [];
my $HASH_REF       = {};
my $CODE_REF       = sub { };

my $GLOB     = do { no warnings 'once'; *GLOB_REF };
my $GLOB_REF = \$GLOB;

open my $FH, '<', $0 or die "Could not open $0 for the test";

my $FH_OBJECT = IO::File->new( $0, 'r' )
    or die "Could not open $0 for the test";

my $REGEX      = qr/../;
my $REGEX_OBJ  = bless qr/../, 'BlessedQR';

my $OBJECT = bless {}, 'Foo';

my $UNDEF = undef;

{
    package Thing;

    sub foo { }
}

my $CLASS_NAME = 'Thing';

{
    package Role;
    use Moose::Role;

    sub foo { }
}

my $ROLE_NAME = 'Role';

my %tests = (
    Any => {
        accept => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $OBJECT,
            $UNDEF,
        ],
    },
    Item => {
        accept => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $OBJECT,
            $UNDEF,
        ],
    },
    Defined => {
        accept => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $OBJECT,
        ],
        reject => [
            $UNDEF,
        ],
    },
    Undef => {
        accept => [
            $UNDEF,
        ],
        reject => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $OBJECT,
        ],
    },
    Bool => {
        accept => [
            $ZERO,
            $ONE,
            $EMPTY_STRING,
            $UNDEF,
        ],
        reject => [
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $OBJECT,
        ],
    },
    Maybe => {
        accept => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $OBJECT,
            $UNDEF,
        ],
    },
    Value => {
        accept => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $GLOB,
        ],
        reject => [
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $OBJECT,
            $UNDEF,
        ],
    },
    Ref => {
        accept => [
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $OBJECT,
        ],
        reject => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $GLOB,
            $UNDEF,
        ],
    },
    Num => {
        accept => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
        ],
        reject => [
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $OBJECT,
            $UNDEF,
        ],
    },
    Int => {
        accept => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
        ],
        reject => [
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $OBJECT,
            $UNDEF,
        ],
    },
    Str => {
        accept => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
        ],
        reject => [
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $OBJECT,
            $UNDEF,
        ],
    },
    ScalarRef => {
        accept => [
            $SCALAR_REF,
            $SCALAR_REF_REF,
        ],
        reject => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $OBJECT,
            $UNDEF,
        ],
    },
    ArrayRef => {
        accept => [
            $ARRAY_REF,
        ],
        reject => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $OBJECT,
            $UNDEF,
        ],
    },
    HashRef => {
        accept => [
            $HASH_REF,
        ],
        reject => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $OBJECT,
            $UNDEF,
        ],
    },
    CodeRef => {
        accept => [
            $CODE_REF,
        ],
        reject => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $OBJECT,
            $UNDEF,
        ],
    },
    RegexpRef => {
        accept => [
            $REGEX,
            $REGEX_OBJ,
        ],
        reject => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $OBJECT,
            $UNDEF,
        ],
    },
    GlobRef => {
        accept => [
            $GLOB_REF,
            $FH,
        ],
        reject => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $FH_OBJECT,
            $OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $UNDEF,
        ],
    },
    FileHandle => {
        accept => [
            $FH,
            $FH_OBJECT,
        ],
        reject => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $UNDEF,
        ],
    },
    Object => {
        accept => [
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $OBJECT,
        ],
        reject => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $UNDEF,
        ],
    },
    ClassName => {
        accept => [
            $CLASS_NAME,
            $ROLE_NAME,
        ],
        reject => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $OBJECT,
            $UNDEF,
        ],
    },
    RoleName => {
        accept => [
            $ROLE_NAME,
        ],
        reject => [
            $CLASS_NAME,
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $OBJECT,
            $UNDEF,
        ],
    },
);

for my $name ( sort keys %tests ) {
    test_constraint( $name, $tests{$name} );
}

# We need to test that the Str constraint accepts the return val of substr() -
# which means passing that return val directly to the checking code
{
    my $str = 'some string';

    my $type = Moose::Util::TypeConstraints::find_type_constraint('Str');

    my $unoptimized
        = $type->has_parent
        ? $type->_compile_subtype( $type->constraint )
        : $type->_compile_type( $type->constraint );

    my $inlined;
    {
        local $@;
        $inlined = eval 'sub { ( ' . $type->_inline_check('$_[0]') . ' ) }';
        die $@ if $@;
    }

    ok(
        $type->check( substr( $str, 1, 3 ) ),
        'Str accepts return val from substr using ->check'
    );
    ok(
        $unoptimized->( substr( $str, 1, 3 ) ),
        'Str accepts return val from substr using unoptimized constraint'
    );
    ok(
        $inlined->( substr( $str, 1, 3 ) ),
        'Str accepts return val from substr using inlined constraint'
    );

    ok(
        $type->check( substr( $str, 0, 0 ) ),
        'Str accepts empty return val from substr using ->check'
    );
    ok(
        $unoptimized->( substr( $str, 0, 0 ) ),
        'Str accepts empty return val from substr using unoptimized constraint'
    );
    ok(
        $inlined->( substr( $str, 0, 0 ) ),
        'Str accepts empty return val from substr using inlined constraint'
    );
}

{
    my $class_tc = class_type('Thing');

    test_constraint(
        $class_tc, {
            accept => [
                ( bless {}, 'Thing' ),
            ],
            reject => [
                'Thing',
                $ZERO,
                $ONE,
                $INT,
                $NEG_INT,
                $NUM,
                $NEG_NUM,
                $EMPTY_STRING,
                $STRING,
                $NUM_IN_STRING,
                $INT_WITH_NL1,
                $INT_WITH_NL2,
                $SCALAR_REF,
                $SCALAR_REF_REF,
                $ARRAY_REF,
                $HASH_REF,
                $CODE_REF,
                $GLOB,
                $GLOB_REF,
                $FH,
                $FH_OBJECT,
                $REGEX,
                $REGEX_OBJ,
                $OBJECT,
                $UNDEF,
            ],
        }
    );
}

{
    package Duck;

    sub quack { }
    sub flap  { }
}

{
    package DuckLike;

    sub quack { }
    sub flap  { }
}

{
    package Bird;

    sub flap { }
}

{
    my @methods = qw( quack flap );
    duck_type 'Duck' => @methods;

    test_constraint(
        'Duck', {
            accept => [
                ( bless {}, 'Duck' ),
                ( bless {}, 'DuckLike' ),
            ],
            reject => [
                $ZERO,
                $ONE,
                $INT,
                $NEG_INT,
                $NUM,
                $NEG_NUM,
                $EMPTY_STRING,
                $STRING,
                $NUM_IN_STRING,
                $INT_WITH_NL1,
                $INT_WITH_NL2,
                $SCALAR_REF,
                $SCALAR_REF_REF,
                $ARRAY_REF,
                $HASH_REF,
                $CODE_REF,
                $GLOB,
                $GLOB_REF,
                $FH,
                $FH_OBJECT,
                $REGEX,
                $REGEX_OBJ,
                $OBJECT,
                ( bless {}, 'Bird' ),
                $UNDEF,
            ],
        }
    );
}

{
    my @allowed = qw( bar baz quux );
    enum 'Enumerated' => @allowed;

    test_constraint(
        'Enumerated', {
            accept => \@allowed,
            reject => [
                $ZERO,
                $ONE,
                $INT,
                $NEG_INT,
                $NUM,
                $NEG_NUM,
                $EMPTY_STRING,
                $STRING,
                $NUM_IN_STRING,
                $INT_WITH_NL1,
                $INT_WITH_NL2,
                $SCALAR_REF,
                $SCALAR_REF_REF,
                $ARRAY_REF,
                $HASH_REF,
                $CODE_REF,
                $GLOB,
                $GLOB_REF,
                $FH,
                $FH_OBJECT,
                $REGEX,
                $REGEX_OBJ,
                $OBJECT,
                $UNDEF,
            ],
        }
    );
}

{
    my $union = Moose::Meta::TypeConstraint::Union->new(
        type_constraints => [
            find_type_constraint('Int'),
            find_type_constraint('Object'),
        ],
    );

    test_constraint(
        $union, {
            accept => [
                $ZERO,
                $ONE,
                $INT,
                $NEG_INT,
                $FH_OBJECT,
                $REGEX,
                $REGEX_OBJ,
                $OBJECT,
            ],
            reject => [
                $NUM,
                $NEG_NUM,
                $EMPTY_STRING,
                $STRING,
                $NUM_IN_STRING,
                $INT_WITH_NL1,
                $INT_WITH_NL2,
                $SCALAR_REF,
                $SCALAR_REF_REF,
                $ARRAY_REF,
                $HASH_REF,
                $CODE_REF,
                $GLOB,
                $GLOB_REF,
                $FH,
                $UNDEF,
            ],
        }
    );
}

{
    package DoesRole;

    use Moose;

    with 'Role';
}

# Test how $_ is used in XS implementation
{
    local $_ = qr/./;
    ok(
        Moose::Util::TypeConstraints::Builtins::_RegexpRef(),
        '$_ is RegexpRef'
    );
    ok(
        !Moose::Util::TypeConstraints::Builtins::_RegexpRef(1),
        '$_ is not read when param provided'
    );

    $_ = bless qr/./, 'Blessed';

    ok(
        Moose::Util::TypeConstraints::Builtins::_RegexpRef(),
        '$_ is RegexpRef'
    );

    $_ = 42;
    ok(
        !Moose::Util::TypeConstraints::Builtins::_RegexpRef(),
        '$_ is not RegexpRef'
    );
    ok(
        Moose::Util::TypeConstraints::Builtins::_RegexpRef(qr/./),
        '$_ is not read when param provided'
    );
}

close $FH
    or warn "Could not close the filehandle $0 for test";
$FH_OBJECT->close
    or warn "Could not close the filehandle $0 for test";

done_testing;

sub test_constraint {
    my $type  = shift;
    my $tests = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    unless ( blessed $type ) {
        $type = Moose::Util::TypeConstraints::find_type_constraint($type)
            or BAIL_OUT("No such type $type!");
    }

    my $name = $type->name;

    my $unoptimized
        = $type->has_parent
        ? $type->_compile_subtype( $type->constraint )
        : $type->_compile_type( $type->constraint );

    my $inlined;
    if ( $type->has_inlined_type_constraint ) {
        local $@;
        $inlined = eval 'sub { ( ' . $type->_inline_check('$_[0]') . ' ) }';
        die $@ if $@;
    }

    for my $accept ( @{ $tests->{accept} || [] } ) {
        my $described = describe($accept);
        ok(
            $type->check($accept),
            "$name accepts $described using ->check"
        );
        ok(
            $unoptimized->($accept),
            "$name accepts $described using unoptimized constraint"
        );
        if ($inlined) {
            ok(
                $inlined->($accept),
                "$name accepts $described using inlined constraint"
            );
        }
    }

    for my $reject ( @{ $tests->{reject} || [] } ) {
        my $described = describe($reject);
        ok(
            !$type->check($reject),
            "$name rejects $described using ->check"
        );
        ok(
            !$unoptimized->($reject),
            "$name rejects $described using unoptimized constraint"
        );
        if ($inlined) {
            ok(
                !$inlined->($reject),
                "$name rejects $described using inlined constraint"
            );
        }
    }
}

sub describe {
    my $val = shift;

    return 'undef' unless defined $val;

    if ( !ref $val ) {
        return q{''} if $val eq q{};

        $val =~ s/\n/\\n/g;

        return $val;
    }

    return 'open filehandle'
        if openhandle $val && !blessed $val;

    return blessed $val
        ? ( ref $val ) . ' object'
        : ( ref $val ) . ' reference';
}
