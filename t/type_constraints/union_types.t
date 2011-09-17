#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Moose::Util::TypeConstraints;

my $Str = find_type_constraint('Str');
isa_ok( $Str, 'Moose::Meta::TypeConstraint' );

my $Undef = find_type_constraint('Undef');
isa_ok( $Undef, 'Moose::Meta::TypeConstraint' );

ok( !$Str->check(undef),      '... Str cannot accept an Undef value' );
ok( $Str->check('String'),    '... Str can accept an String value' );
ok( !$Undef->check('String'), '... Undef cannot accept an Str value' );
ok( $Undef->check(undef),     '... Undef can accept an Undef value' );

my $Str_or_Undef = Moose::Meta::TypeConstraint::Union->new(
    type_constraints => [ $Str, $Undef ] );
isa_ok( $Str_or_Undef, 'Moose::Meta::TypeConstraint::Union' );

ok(
    $Str_or_Undef->check(undef),
    '... (Str | Undef) can accept an Undef value'
);
ok(
    $Str_or_Undef->check('String'),
    '... (Str | Undef) can accept a String value'
);

ok( !$Str_or_Undef->is_a_type_of($Str),   "not a subtype of Str" );
ok( !$Str_or_Undef->is_a_type_of($Undef), "not a subtype of Undef" );

cmp_ok(
    $Str_or_Undef->find_type_for('String'), 'eq', 'Str',
    'find_type_for Str'
);
cmp_ok(
    $Str_or_Undef->find_type_for(undef), 'eq', 'Undef',
    'find_type_for Undef'
);
ok(
    !defined( $Str_or_Undef->find_type_for( sub { } ) ),
    'no find_type_for CodeRef'
);

ok( !$Str_or_Undef->equals($Str),         "not equal to Str" );
ok( $Str_or_Undef->equals($Str_or_Undef), "equal to self" );
ok(
    $Str_or_Undef->equals(
        Moose::Meta::TypeConstraint::Union->new(
            type_constraints => [ $Str, $Undef ]
        )
    ),
    "equal to clone"
);
ok(
    $Str_or_Undef->equals(
        Moose::Meta::TypeConstraint::Union->new(
            type_constraints => [ $Undef, $Str ]
        )
    ),
    "equal to reversed clone"
);

ok(
    !$Str_or_Undef->is_a_type_of("ThisTypeDoesNotExist"),
    "not type of non existent type"
);
ok(
    !$Str_or_Undef->is_subtype_of("ThisTypeDoesNotExist"),
    "not subtype of non existent type"
);

is(
    $Str_or_Undef->parent,
    find_type_constraint('Item'),
    'parent of Str|Undef is Item'
);

is(
    $Str_or_Undef->parents,
    find_type_constraint('Item'),
    'parents of Str|Undef is Item'
);

# another ....

my $ArrayRef = find_type_constraint('ArrayRef');
isa_ok( $ArrayRef, 'Moose::Meta::TypeConstraint' );

my $HashRef = find_type_constraint('HashRef');
isa_ok( $HashRef, 'Moose::Meta::TypeConstraint' );

ok( $ArrayRef->check( [] ), '... ArrayRef can accept an [] value' );
ok( !$ArrayRef->check( {} ), '... ArrayRef cannot accept an {} value' );
ok( $HashRef->check(   {} ), '... HashRef can accept an {} value' );
ok( !$HashRef->check( [] ), '... HashRef cannot accept an [] value' );

my $ArrayRef_or_HashRef = Moose::Meta::TypeConstraint::Union->new(
    type_constraints => [ $ArrayRef, $HashRef ] );
isa_ok( $ArrayRef_or_HashRef, 'Moose::Meta::TypeConstraint::Union' );

ok( $ArrayRef_or_HashRef->check( [] ),
    '... (ArrayRef | HashRef) can accept []' );
ok( $ArrayRef_or_HashRef->check( {} ),
    '... (ArrayRef | HashRef) can accept {}' );

ok(
    !$ArrayRef_or_HashRef->check( \( my $var1 ) ),
    '... (ArrayRef | HashRef) cannot accept scalar refs'
);
ok(
    !$ArrayRef_or_HashRef->check( sub { } ),
    '... (ArrayRef | HashRef) cannot accept code refs'
);
ok(
    !$ArrayRef_or_HashRef->check(50),
    '... (ArrayRef | HashRef) cannot accept Numbers'
);

diag $ArrayRef_or_HashRef->validate( [] );

ok(
    !defined( $ArrayRef_or_HashRef->validate( [] ) ),
    '... (ArrayRef | HashRef) can accept []'
);
ok(
    !defined( $ArrayRef_or_HashRef->validate( {} ) ),
    '... (ArrayRef | HashRef) can accept {}'
);

like(
    $ArrayRef_or_HashRef->validate( \( my $var2 ) ),
    qr/Validation failed for \'ArrayRef\' with value .+ and Validation failed for \'HashRef\' with value .+ in \(ArrayRef\|HashRef\)/,
    '... (ArrayRef | HashRef) cannot accept scalar refs'
);

like(
    $ArrayRef_or_HashRef->validate( sub { } ),
    qr/Validation failed for \'ArrayRef\' with value .+ and Validation failed for \'HashRef\' with value .+ in \(ArrayRef\|HashRef\)/,
    '... (ArrayRef | HashRef) cannot accept code refs'
);

is(
    $ArrayRef_or_HashRef->validate(50),
    'Validation failed for \'ArrayRef\' with value 50 and Validation failed for \'HashRef\' with value 50 in (ArrayRef|HashRef)',
    '... (ArrayRef | HashRef) cannot accept Numbers'
);

is(
    $ArrayRef_or_HashRef->parent,
    find_type_constraint('Ref'),
    'parent of ArrayRef|HashRef is Ref'
);

done_testing;
