#!/usr/bin/perl

use strict;
use warnings;

use Test::Fatal;
use Test::More;

use Moose::Util::TypeConstraints;

#<<<
subtype 'Inlinable',
    as 'Str',
    where       { $_ !~ /Q/ },
    inline_as   { "defined $_[1] && ! ref $_[1] && $_[1] !~ /Q/" };

subtype 'NotInlinable',
    as 'Str',
    where { $_ !~ /Q/ };
#>>>

my $inlinable     = find_type_constraint('Inlinable');
my $not_inlinable = find_type_constraint('NotInlinable');

{
    ok(
        $inlinable->has_inlined_type_constraint,
        'Inlinable returns true for has_inlined_type_constraint'
    );

    is(
        $inlinable->_inline_check('$foo'),
        'defined $foo && ! ref $foo && $foo !~ /Q/',
        'got expected inline code for Inlinable constraint'
    );

    ok(
        !$not_inlinable->has_inlined_type_constraint,
        'NotInlinable returns false for has_inlined_type_constraint'
    );

    like(
        exception { $not_inlinable->_inline_check('$foo') },
        qr/Cannot inline a type constraint check for NotInlinable/,
        'threw an exception when asking for inlinable code from type which cannot be inlined'
    );
}

{
    my $aofi = Moose::Util::TypeConstraints::find_or_create_type_constraint(
        'ArrayRef[Inlinable]');

    ok(
        $aofi->has_inlined_type_constraint,
        'ArrayRef[Inlinable] returns true for has_inlined_type_constraint'
    );

    is(
        $aofi->_inline_check('$foo'),
        q{ref $foo eq 'ARRAY' && &List::MoreUtils::all( sub { defined $_ && ! ref $_ && $_ !~ /Q/ }, @{$foo} )},
        'got expected inline code for ArrayRef[Inlinable] constraint'
    );

    my $aofni = Moose::Util::TypeConstraints::find_or_create_type_constraint(
        'ArrayRef[NotInlinable]');

    ok(
        !$aofni->has_inlined_type_constraint,
        'ArrayRef[NotInlinable] returns false for has_inlined_type_constraint'
    );
}

subtype 'ArrayOfInlinable',
    as 'ArrayRef[Inlinable]';

subtype 'ArrayOfNotInlinable',
    as 'ArrayRef[NotInlinable]';
{
    my $aofi = Moose::Util::TypeConstraints::find_or_create_type_constraint(
        'ArrayOfInlinable');

    ok(
        $aofi->has_inlined_type_constraint,
        'ArrayOfInlinable returns true for has_inlined_type_constraint'
    );

    is(
        $aofi->_inline_check('$foo'),
        q{ref $foo eq 'ARRAY' && &List::MoreUtils::all( sub { defined $_ && ! ref $_ && $_ !~ /Q/ }, @{$foo} )},
        'got expected inline code for ArrayOfInlinable constraint'
    );

    my $aofni = Moose::Util::TypeConstraints::find_or_create_type_constraint(
        'ArrayOfNotInlinable');

    ok(
        !$aofni->has_inlined_type_constraint,
        'ArrayOfNotInlinable returns false for has_inlined_type_constraint'
    );
}

{
    my $hoaofi = Moose::Util::TypeConstraints::find_or_create_type_constraint(
        'HashRef[ArrayRef[Inlinable]]');

    ok(
        $hoaofi->has_inlined_type_constraint,
        'HashRef[ArrayRef[Inlinable]] returns true for has_inlined_type_constraint'
    );

    is(
        $hoaofi->_inline_check('$foo'),
        q{ref $foo eq 'HASH' && &List::MoreUtils::all( sub { ref $_ eq 'ARRAY' && &List::MoreUtils::all( sub { defined $_ && ! ref $_ && $_ !~ /Q/ }, @{$_} ) }, values %{$foo} )},
        'got expected inline code for HashRef[ArrayRef[Inlinable]] constraint'
    );

    my $hoaofni = Moose::Util::TypeConstraints::find_or_create_type_constraint(
        'HashRef[ArrayRef[NotInlinable]]');

    ok(
        !$hoaofni->has_inlined_type_constraint,
        'HashRef[ArrayRef[NotInlinable]] returns false for has_inlined_type_constraint'
    );
}

{
    my $iunion = Moose::Util::TypeConstraints::find_or_create_type_constraint(
        'Inlinable | Object');

    ok(
        $iunion->has_inlined_type_constraint,
        'Inlinable | Object returns true for has_inlined_type_constraint'
    );

    is(
        $iunion->_inline_check('$foo'),
        '(defined $foo && ! ref $foo && $foo !~ /Q/) || (Scalar::Util::blessed( $foo ))',
        'got expected inline code for Inlinable | Object constraint'
    );

    my $niunion = Moose::Util::TypeConstraints::find_or_create_type_constraint(
        'NotInlinable | Object');

    ok(
        !$niunion->has_inlined_type_constraint,
        'NotInlinable | Object returns false for has_inlined_type_constraint'
    );
}

{
    my $iunion = Moose::Util::TypeConstraints::find_or_create_type_constraint(
        'Object | Inlinable');

    ok(
        $iunion->has_inlined_type_constraint,
        'Object | Inlinable returns true for has_inlined_type_constraint'
    );

    is(
        $iunion->_inline_check('$foo'),
        '(Scalar::Util::blessed( $foo )) || (defined $foo && ! ref $foo && $foo !~ /Q/)',
        'got expected inline code for Object | Inlinable constraint'
    );

    my $niunion = Moose::Util::TypeConstraints::find_or_create_type_constraint(
        'Object | NotInlinable');

    ok(
        !$niunion->has_inlined_type_constraint,
        'Object | NotInlinable returns false for has_inlined_type_constraint'
    );
}

{
    my $iunion = Moose::Util::TypeConstraints::find_or_create_type_constraint(
        'Object | Inlinable | CodeRef');

    ok(
        $iunion->has_inlined_type_constraint,
        'Object | Inlinable | CodeRef returns true for has_inlined_type_constraint'
    );

    is(
        $iunion->_inline_check('$foo'),
        q{(Scalar::Util::blessed( $foo )) || (defined $foo && ! ref $foo && $foo !~ /Q/) || (ref $foo eq 'CODE')},
        'got expected inline code for Object | Inlinable | CodeRef constraint'
    );

    my $niunion = Moose::Util::TypeConstraints::find_or_create_type_constraint(
        'Object | NotInlinable | CodeRef');

    ok(
        !$niunion->has_inlined_type_constraint,
        'Object | NotInlinable | CodeRef returns false for has_inlined_type_constraint'
    );
}

done_testing;
