#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;
use Test::Exception;

BEGIN {
    use_ok('Moose');
}

BEGIN {
    package MyFramework::Base;
    use Moose;
    
    package MyFramework::Meta::Base;
    use Moose;  
    
    extends 'Moose::Meta::Class';  
    
    package MyFramework;
    use Moose;

    sub import {
        my $CALLER = caller();

        strict->import;
        warnings->import;
        
        return if $CALLER eq 'main';
        Moose::init_meta( $CALLER, 'MyFramework::Base', 'MyFramework::Meta::Base' );
        Moose->import({ into => $CALLER });

        return 1;
    }
}

{   
    package MyClass;
    BEGIN { MyFramework->import }
    
    has 'foo' => (is => 'rw');
}

can_ok( 'MyClass', 'meta' );

isa_ok(MyClass->meta, 'MyFramework::Meta::Base');
isa_ok(MyClass->meta, 'Moose::Meta::Class');

my $obj = MyClass->new(foo => 10);
isa_ok($obj, 'MyClass');
isa_ok($obj, 'MyFramework::Base');
isa_ok($obj, 'Moose::Object');

is($obj->foo, 10, '... got the right value');




