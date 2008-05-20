#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;

BEGIN {
    use_ok('Moose');
}

{

    package Dog;
    use Moose;

    sub bark_once {
        my $self = shift;
        return 'bark';
    }

    sub bark_twice {
        return 'barkbark';
    }

    around qr/bark.*/ => sub {
        'Dog::around';
    };

}

my $dog = Dog->new;
is( $dog->bark_once,  'Dog::around', 'around modifier is called' );
is( $dog->bark_twice, 'Dog::around', 'around modifier is called' );

{

    package Cat;
    use Moose;
    our $BEFORE_BARK_COUNTER = 0;
    our $AFTER_BARK_COUNTER  = 0;

    sub bark_once {
        my $self = shift;
        return 'bark';
    }

    sub bark_twice {
        return 'barkbark';
    }

    before qr/bark.*/ => sub {
        $BEFORE_BARK_COUNTER++;
    };

    after qr/bark.*/ => sub {
        $AFTER_BARK_COUNTER++;
    };

}

my $cat = Cat->new;
$cat->bark_once;
is( $Cat::BEFORE_BARK_COUNTER, 1, 'before modifier is called once' );
is( $Cat::AFTER_BARK_COUNTER,  1, 'after modifier is called once' );
$cat->bark_twice;
is( $Cat::BEFORE_BARK_COUNTER, 2, 'before modifier is called twice' );
is( $Cat::AFTER_BARK_COUNTER,  2, 'after modifier is called twice' );

{

    package Animal;
    use Moose;
    our $BEFORE_BARK_COUNTER = 0;
    our $AFTER_BARK_COUNTER  = 0;

    sub bark_once {
        my $self = shift;
        return 'bark';
    }

    sub bark_twice {
        return 'barkbark';
    }

    before qr/bark.*/ => sub {
        $BEFORE_BARK_COUNTER++;
    };

    after qr/bark.*/ => sub {
        $AFTER_BARK_COUNTER++;
    };
}

{

    package Cow;
    use Moose;
    extends 'Animal';

    override 'bark_once' => sub {
        my $self = shift;
        super();
        return 'cow';
    };

    override 'bark_twice' => sub {
        super();        
        return 'cowcow';
    };
}

{
    my $cow = Cow->new;
    $cow->bark_once;
    is( $Animal::BEFORE_BARK_COUNTER, 1,
        'before modifier is called if method is overridden' );
    is( $Animal::AFTER_BARK_COUNTER, 1,
        'after modifier is called if method is overridden' );
}

{

    package MyDog;
    use Moose;
    our $BEFORE_BARK_COUNTER=0;
    sub bark {
        my $self = shift;
        return 'bark';
    }
    
    sub bark_twice {
        my $self = shift;
        return 'barkbark';
    }

    before qw/bark bark_twice/ => sub {
        $BEFORE_BARK_COUNTER++;
    };

}

my $my_dog = MyDog->new;
$my_dog->bark;
$my_dog->bark_twice;
is($MyDog::BEFORE_BARK_COUNTER, 2, "before method modifier is called twice");

