#!/usr/local/bin/perl

use strict;
use warnings;

use Test::More no_plan => 1;

=pod

This is an example of making Moose behave 
more like a prototype based object system.

Why? 

Well cause merlyn asked if it could :)

=cut

## ------------------------------------------------------------------
## make some metaclasses

{
    package ProtoMoose::Meta::Instance;
    use Moose;
    
    BEGIN { extends 'Moose::Meta::Instance' };
    
    # NOTE:
    # do not let things be inlined by
    # the attribute or accessor generator
    sub is_inlinable { 0 }
}

{
    package ProtoMoose::Meta::Method::Accessor;
    use Moose;
    
    BEGIN { extends 'Moose::Meta::Method::Accessor' };
    
    # customize the accessors to always grab 
    # the ->meta->sole_instance in the accessors
    
    sub generate_accessor_method {
        my $attr = (shift)->associated_attribute; 
        return sub {
            my $self = blessed($_[0]) ? $_[0] : $_[0]->meta->sole_instance;
            $attr->set_value($self, $_[1]) if scalar(@_) == 2;
            $attr->get_value($self);
        };
    }

    sub generate_reader_method {
        my $attr = (shift)->associated_attribute; 
        return sub { 
            my $self = blessed($_[0]) ? $_[0] : $_[0]->meta->sole_instance;
            confess "Cannot assign a value to a read-only accessor" if @_ > 1;
            $attr->get_value($self);
        };   
    }

    sub generate_writer_method {
        my $attr = (shift)->associated_attribute; 
        return sub {
            my $self = blessed($_[0]) ? $_[0] : $_[0]->meta->sole_instance;
            $attr->set_value($self, $_[1]);
        };
    }

    # deal with these later ...
    sub generate_predicate_method {}
    sub generate_clearer_method {}    
    
}

{
    package ProtoMoose::Meta::Attribute;
    use Moose;
    
    BEGIN { extends 'Moose::Meta::Attribute' };

    sub accessor_metaclass { 'ProtoMoose::Meta::Method::Accessor' }
}

{
    package ProtoMoose::Meta::Class;
    use Moose;
    
    BEGIN { extends 'Moose::Meta::Class' };
    
    has 'sole_instance' => (
        is        => 'rw',
        isa       => 'Object',
        predicate => 'has_sole_instance',
        lazy      => 1,
        default   => sub { (shift)->new_object }
    );
    
    sub initialize {
        # NOTE:
        # I am not sure why 'around' does 
        # not work here, have to investigate
        # it later - SL
        (shift)->SUPER::initialize(@_, 
            instance_metaclass  => 'ProtoMoose::Meta::Instance',
            attribute_metaclass => 'ProtoMoose::Meta::Attribute',            
        );
    }
    
    around 'construct_instance' => sub {
        my $next = shift;
        my $self = shift;
        # NOTE:
        # we actually have to do this here
        # to tie-the-knot, if you take it 
        # out, then you get deep recursion 
        # several levels deep :)
        $self->sole_instance($next->($self, @_)) 
            unless $self->has_sole_instance;
        return $self->sole_instance;
    };
}

## ------------------------------------------------------------------
## make some classes now

{
    package Foo;
    use metaclass 'ProtoMoose::Meta::Class';
    use Moose;
    
    has 'bar' => (is => 'rw');
}

{
    package Bar;
    use Moose;
    
    extends 'Foo';
    
    has 'baz' => (is => 'rw');
}

## ------------------------------------------------------------------

diag "Check that metaclasses are working/inheriting properly";

foreach my $class (qw/Foo Bar/) {
    isa_ok($class->meta, 
    'ProtoMoose::Meta::Class', 
    '... got the right metaclass for ' . $class . ' ->');

    is($class->meta->instance_metaclass, 
    'ProtoMoose::Meta::Instance', 
    '... got the right instance meta for ' . $class);

    is($class->meta->attribute_metaclass, 
    'ProtoMoose::Meta::Attribute', 
    '... got the right attribute meta for ' . $class);
}

## ------------------------------------------------------------------

diag "Check the singleton-ness of them";

my $foo = Foo->new;
is($foo, Foo->meta->sole_instance, '... got the same instance of Foo');

# the sole instance can also be created lazily 
my $sole_bar_instance = Bar->meta->sole_instance;
isa_ok($sole_bar_instance, 'Bar');

my $bar = Bar->new;
is($bar, $sole_bar_instance, '... got the same instance of Bar');

isnt($bar, $foo, '... but foo and bar are not the same instances');

$foo->bar(100);
is($foo->bar, 100, '... got the value I just assigned in foo');
is(Foo->meta->sole_instance->bar, 100, '... got the value I just assigned (in Foo meta-land)');
is(Foo->bar, 100, '... got the value I just assigned in foo (from class style accessor)');

$bar->bar(200);
is($bar->bar, 200, '... got the value I just assigned in bar');
is(Bar->meta->sole_instance->bar, 200, '... got the value I just assigned (in Bar meta-land)');
is(Bar->bar, 200, '... got the value I just assigned in bar (from class style accessor)');

is($foo->bar, 100, '... still got the value I just assigned in Foo');
is(Foo->meta->sole_instance->bar, 100, '... still got the value I just assigned (in meta-land)');

## ------------------------------------------------------------------




