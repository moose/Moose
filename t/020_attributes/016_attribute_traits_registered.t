#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 13;
use Test::Exception;
use Test::Moose;

BEGIN {
    use_ok('Moose');
}

{
    package My::Attribute::Trait;
    use Moose::Role;
    
    has 'alias_to' => (is => 'ro', isa => 'Str');
    
    after 'install_accessors' => sub {
        my $self = shift;
        $self->associated_class->add_method(
            $self->alias_to, 
            $self->get_read_method_ref
        );
    };
    
    package Moose::Meta::Attribute::Custom::Trait::Aliased;
    sub register_implementation { 'My::Attribute::Trait' }
}

{
    package My::Other::Attribute::Trait;
    use Moose::Role;
    
    my $method = sub {
        42;
    };   
 
    after 'install_accessors' => sub {
        my $self = shift;
        $self->associated_class->add_method(
            'additional_method', 
            $method
        );
    };
    
    package Moose::Meta::Attribute::Custom::Trait::Other;
    sub register_implementation { 'My::Other::Attribute::Trait' }
}

{
    package My::Class;
    use Moose;
    
    has 'bar' => (
        traits   => [qw/Aliased/],
        is       => 'ro',
        isa      => 'Int',
        alias_to => 'baz',
    );
}

{   
    package My::Derived::Class;
    use Moose;

    extends 'My::Class';

    has '+bar' => (
        traits   => [qw/Other/],
    );
}

my $c = My::Class->new(bar => 100);
isa_ok($c, 'My::Class');

is($c->bar, 100, '... got the right value for bar');

can_ok($c, 'baz') and
is($c->baz, 100, '... got the right value for baz');

does_ok($c->meta->get_attribute('bar'), 'My::Attribute::Trait');

my $quux = My::Derived::Class->new(bar => 1000);

is($quux->bar, 1000, '... got the right value for bar');

can_ok($quux, 'baz');
is($quux->baz, 1000, '... got the right value for baz');
ok($quux->meta->get_attribute('bar')->does('My::Attribute::Trait'));

TODO: {
    local $TODO = 'These do not pass - bug?';
    SKIP: {
        skip 'no additional_method, so cannot test its value', 1 if !can_ok($quux, 'additional_method');
        is($quux->additional_method, 42, '... got the right value for additional_method');
    }
    ok($quux->meta->get_attribute('bar')->does('My::Other::Attribute::Trait'));
}
