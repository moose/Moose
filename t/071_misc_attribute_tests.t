#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 14;
use Test::Exception;

BEGIN {
    use_ok('Moose');
}

{
    {
        package Test::Attribute::Inline::Documentation;
        use Moose;

        has 'foo' => (
            documentation => q{
                The 'foo' attribute is my favorite
                attribute in the whole wide world.
            }
        );
    }

    my $foo_attr = Test::Attribute::Inline::Documentation->meta->get_attribute('foo');

    ok($foo_attr->has_documentation, '... the foo has docs');
    is($foo_attr->documentation,
            q{
                The 'foo' attribute is my favorite
                attribute in the whole wide world.
            },
    '... got the foo docs');
}

{
    {
        package Test::For::Lazy::TypeConstraint;
        use Moose;
        use Moose::Util::TypeConstraints;

        has 'bad_lazy_attr' => (
            is => 'rw',
            isa => 'ArrayRef',
            lazy => 1,
            default => sub { "test" },
        );

        has 'good_lazy_attr' => (
            is => 'rw',
            isa => 'ArrayRef',
            lazy => 1,
            default => sub { [] },
        );

    }

    my $test = Test::For::Lazy::TypeConstraint->new;
    isa_ok($test, 'Test::For::Lazy::TypeConstraint');

    dies_ok {
        $test->bad_lazy_attr;
    } '... this does not work';

    lives_ok {
        $test->good_lazy_attr;
    } '... this does not work';
}

{
    {
        package Test::Arrayref::Attributes;
        use Moose;

        has [qw(foo bar baz)] => (
            is => 'rw',
        );

    }

    my $test = Test::Arrayref::Attributes->new;
    isa_ok($test, 'Test::Arrayref::Attributes');
    can_ok($test, qw(foo bar baz));

}

{
    {
        package Test::UndefDefault::Attributes;
        use Moose;

        has 'foo' => (
            is      => 'ro',
            isa     => 'Str',
            default => sub { return }
        );

    }

    dies_ok {
        Test::UndefDefault::Attributes->new;
    } '... default must return a value which passes the type constraint';

}

{
    {
        package OverloadedStr;
        use Moose;
        use overload '""' => sub { 'this is *not* a string' };

        has 'a_str' => ( isa => 'Str' , is => 'rw' );
    }

    my $moose_obj = OverloadedStr->new;

    is($moose_obj->a_str( 'foobar' ), 'foobar', 'setter took string');
    ok($moose_obj, 'this is a *not* a string');

    throws_ok {
        $moose_obj->a_str( $moose_obj )
    } qr/Attribute \(a_str\) does not pass the type constraint \(Str\) with OverloadedStr\=HASH\(.*?\)/, '... dies without overloading the string';

}

{
    {
        package OverloadBreaker;
        use Moose;

        has 'a_num' => ( isa => 'Int' , is => 'rw', default => 7.5 );
    }

    throws_ok {
        OverloadBreaker->new;
    } qr/Attribute \(a_num\) does not pass the type constraint \(Int\) with \'7\.5\'/, '... this doesnt trip overload to break anymore ';

    lives_ok {
        OverloadBreaker->new(a_num => 5);
    } '... this works fine though';

}



