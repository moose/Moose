#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 42;
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
    } qr/Attribute \(a_str\) does not pass the type constraint because\: Validation failed for 'Str' failed with value OverloadedStr=HASH\(0x.+?\)/, 
    '... dies without overloading the string';

}

{
    {
        package OverloadBreaker;
        use Moose;

        has 'a_num' => ( isa => 'Int' , is => 'rw', default => 7.5 );
    }

    throws_ok {
        OverloadBreaker->new;
    } qr/Attribute \(a_num\) does not pass the type constraint because\: Validation failed for 'Int' failed with value 7\.5/, 
    '... this doesnt trip overload to break anymore ';

    lives_ok {
        OverloadBreaker->new(a_num => 5);
    } '... this works fine though';

}

{
    {
      package Test::Builder::Attribute;
        use Moose;

        has 'foo'  => ( required => 1, builder => 'build_foo', is => 'ro');
        sub build_foo { return "works" };
    }

    my $meta = Test::Builder::Attribute->meta;
    my $foo_attr  = $meta->get_attribute("foo");

    ok($foo_attr->is_required, "foo is required");
    ok($foo_attr->has_builder, "foo has builder");
    is($foo_attr->builder, "build_foo",  ".. and it's named build_foo");

    my $instance = Test::Builder::Attribute->new;
    is($instance->foo, 'works', "foo builder works");
}

{    
    {
        package Test::Builder::Attribute::Broken;
        use Moose;

        has 'foo'  => ( required => 1, builder => 'build_foo', is => 'ro');
    }
    
    dies_ok {
        Test::Builder::Attribute::Broken->new;
    } '... no builder, wtf';
}


{
    {
      package Test::LazyBuild::Attribute;
        use Moose;

        has 'foo'  => ( lazy_build => 1, is => 'ro');
        has '_foo' => ( lazy_build => 1, is => 'ro');
        has 'fool' => ( lazy_build => 1, is => 'ro');
        sub _build_foo { return "works" };
        sub _build__foo { return "works too" };
    }

    my $meta = Test::LazyBuild::Attribute->meta;
    my $foo_attr  = $meta->get_attribute("foo");
    my $_foo_attr = $meta->get_attribute("_foo");

    ok($foo_attr->is_lazy, "foo is lazy");
    ok($foo_attr->is_required, "foo is required");
    ok($foo_attr->is_lazy_build, "foo is lazy_build");

    ok($foo_attr->has_clearer, "foo has clearer");
    is($foo_attr->clearer, "clear_foo",  ".. and it's named clear_foo");

    ok($foo_attr->has_builder, "foo has builder");
    is($foo_attr->builder, "_build_foo",  ".. and it's named build_foo");

    ok($foo_attr->has_predicate, "foo has predicate");
    is($foo_attr->predicate, "has_foo",  ".. and it's named has_foo");

    ok($_foo_attr->is_lazy, "_foo is lazy");
    ok($_foo_attr->is_required, "_foo is required");
    ok($_foo_attr->is_lazy_build, "_foo is lazy_build");

    ok($_foo_attr->has_clearer, "_foo has clearer");
    is($_foo_attr->clearer, "_clear_foo",  ".. and it's named _clear_foo");

    ok($_foo_attr->has_builder, "_foo has builder");
    is($_foo_attr->builder, "_build__foo",  ".. and it's named _build_foo");

    ok($_foo_attr->has_predicate, "_foo has predicate");
    is($_foo_attr->predicate, "_has_foo",  ".. and it's named _has_foo");

    my $instance = Test::LazyBuild::Attribute->new;
    ok(!$instance->has_foo, "noo foo value yet");
    ok(!$instance->_has_foo, "noo _foo value yet");
    is($instance->foo, 'works', "foo builder works");
    is($instance->_foo, 'works too', "foo builder works too");
    throws_ok { $instance->fool }
        qr/Test::LazyBuild::Attribute does not support builder method \'_build_fool\' for attribute \'fool\'/,
            "Correct error when a builder method is not present";

}

