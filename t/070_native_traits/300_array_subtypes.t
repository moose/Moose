#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

{
    use Moose::Util::TypeConstraints;
    use List::Util qw(sum);

    subtype 'A1', as 'ArrayRef[Int]';
    subtype 'A2', as 'ArrayRef',      where { @$_ < 2 };
    subtype 'A3', as 'ArrayRef[Int]', where { sum @$_ < 5 };

    no Moose::Util::TypeConstraints;
}

{
    package Foo;
    use Moose;

    has array => (
        traits  => ['Array'],
        is      => 'rw',
        isa     => 'ArrayRef',
        handles => {
            push_array => 'push',
        },
    );
    has array_int => (
        traits  => ['Array'],
        is      => 'rw',
        isa     => 'ArrayRef[Int]',
        handles => {
            push_array_int => 'push',
        },
    );
    has a1 => (
        traits  => ['Array'],
        is      => 'rw',
        isa     => 'A1',
        handles => {
            push_a1 => 'push',
        },
    );
    has a2 => (
        traits  => ['Array'],
        is      => 'rw',
        isa     => 'A2',
        handles => {
            push_a2 => 'push',
        },
    );
    has a3 => (
        traits  => ['Array'],
        is      => 'rw',
        isa     => 'A3',
        handles => {
            push_a3 => 'push',
        },
    );
}

my $foo = Foo->new;

{
    my $array = [];
    dies_ok { $foo->push_array('foo') } "can't push onto undef";

    $foo->array($array);
    is($foo->array, $array, "same ref");
    is_deeply($foo->array, [], "correct contents");

    $foo->push_array('foo');
    is($foo->array, $array, "same ref");
    is_deeply($foo->array, ['foo'], "correct contents");
}

{
    my $array = [];
    dies_ok { $foo->push_array_int(1) } "can't push onto undef";

    $foo->array_int($array);
    is($foo->array_int, $array, "same ref");
    is_deeply($foo->array_int, [], "correct contents");

    dies_ok { $foo->push_array_int('foo') } "can't push wrong type";
    is($foo->array_int, $array, "same ref");
    is_deeply($foo->array_int, [], "correct contents");
    @$array = ();

    $foo->push_array_int(1);
    is($foo->array_int, $array, "same ref");
    is_deeply($foo->array_int, [1], "correct contents");
}

{
    my $array = [];
    dies_ok { $foo->push_a1('foo') } "can't push onto undef";

    $foo->a1($array);
    is($foo->a1, $array, "same ref");
    is_deeply($foo->a1, [], "correct contents");

    { local $TODO = "type parameters aren't checked on subtypes";
    dies_ok { $foo->push_a1('foo') } "can't push wrong type";
    }
    is($foo->a1, $array, "same ref");
    { local $TODO = "type parameters aren't checked on subtypes";
    is_deeply($foo->a1, [], "correct contents");
    }
    @$array = ();

    $foo->push_a1(1);
    is($foo->a1, $array, "same ref");
    is_deeply($foo->a1, [1], "correct contents");
}

{
    my $array = [];
    dies_ok { $foo->push_a2('foo') } "can't push onto undef";

    $foo->a2($array);
    is($foo->a2, $array, "same ref");
    is_deeply($foo->a2, [], "correct contents");

    $foo->push_a2('foo');
    is($foo->a2, $array, "same ref");
    is_deeply($foo->a2, ['foo'], "correct contents");

    { local $TODO = "overall tcs aren't checked";
    dies_ok { $foo->push_a2('bar') } "can't push more than one element";
    }
    is($foo->a2, $array, "same ref");
    { local $TODO = "overall tcs aren't checked";
    is_deeply($foo->a2, ['foo'], "correct contents");
    }
}

{
    my $array = [];
    dies_ok { $foo->push_a3(1) } "can't push onto undef";

    $foo->a3($array);
    is($foo->a3, $array, "same ref");
    is_deeply($foo->a3, [], "correct contents");

    { local $TODO = "tc parameters aren't checked on subtypes";
    dies_ok { $foo->push_a3('foo') } "can't push non-int";
    }
    { local $TODO = "overall tcs aren't checked";
    dies_ok { $foo->push_a3(100) } "can't violate overall type constraint";
    }
    is($foo->a3, $array, "same ref");
    { local $TODO = "tc checks are broken";
    is_deeply($foo->a3, [], "correct contents");
    }
    @$array = ();

    $foo->push_a3(1);
    is($foo->a3, $array, "same ref");
    is_deeply($foo->a3, [1], "correct contents");

    { local $TODO = "overall tcs aren't checked";
    dies_ok { $foo->push_a3(100) } "can't violate overall type constraint";
    }
    is($foo->a3, $array, "same ref");
    { local $TODO = "overall tcs aren't checked";
    is_deeply($foo->a3, [1], "correct contents");
    }
    @$array = (1);

    $foo->push_a3(3);
    is($foo->a3, $array, "same ref");
    is_deeply($foo->a3, [1, 3], "correct contents");
}

done_testing;
