use strict;
use warnings;

use Test::More;
use Test::Fatal;

{

    package Foo;
    use Moose;
    use Moose::Util::TypeConstraints;

    subtype 'UCArray', as 'ArrayRef[Str]', where {
        !grep {/[a-z]/} @{$_};
    };

    coerce 'UCArray', from 'ArrayRef[Str]', via {
        [ map { uc $_ } @{$_} ];
    };

    has array => (
        traits  => ['Array'],
        is      => 'rw',
        isa     => 'UCArray',
        coerce  => 1,
        handles => {
            push_array => 'push',
            set_array  => 'set',
        },
    );

    our @TriggerArgs;

    has lazy => (
        traits  => ['Array'],
        is      => 'rw',
        isa     => 'UCArray',
        coerce  => 1,
        lazy    => 1,
        default => sub { ['a'] },
        handles => {
            push_lazy => 'push',
            set_lazy  => 'set',
        },
        trigger => sub { @TriggerArgs = @_ },
        clearer => 'clear_lazy',
    );
}

my $foo = Foo->new;

{
    $foo->array( [qw( A B C )] );

    $foo->push_array('d');

    is_deeply(
        $foo->array, [qw( A B C D )],
        'push coerces the array'
    );

    $foo->set_array( 1 => 'x' );

    is_deeply(
        $foo->array, [qw( A X C D )],
        'set coerces the array'
    );
}

{
    $foo->push_lazy('d');

    is_deeply(
        $foo->lazy, [qw( A D )],
        'push coerces the array - lazy'
    );

    is_deeply(
        \@Foo::TriggerArgs,
        [ $foo, [qw( A D )], ['A'] ],
        'trigger receives expected arguments'
    );

    $foo->set_lazy( 2 => 'f' );

    is_deeply(
        $foo->lazy, [qw( A D F )],
        'set coerces the array - lazy'
    );

    is_deeply(
        \@Foo::TriggerArgs,
        [ $foo, [qw( A D F )], [qw( A D )] ],
        'trigger receives expected arguments'
    );
}

{
    package Thing;
    use Moose;

    has thing => (
        is  => 'ro',
        isa => 'Str',
    );
}

{
    package Bar;
    use Moose;
    use Moose::Util::TypeConstraints;

    class_type 'Thing';

    coerce 'Thing'
        => from 'Str'
        => via { Thing->new( thing => $_ ) };

    subtype 'ArrayRefOfThings'
        => as 'ArrayRef[Thing]';

    coerce 'ArrayRefOfThings'
        => from 'ArrayRef[Str]'
        => via { [ map { Thing->new( thing => $_ ) } @{$_} ] };

    coerce 'ArrayRefOfThings'
        => from 'Str'
        => via { [ Thing->new( thing => $_ ) ] };

    has array => (
        traits  => ['Array'],
        is      => 'rw',
        isa     => 'ArrayRefOfThings',
        coerce  => 1,
        handles => {
            push_array   => 'push',
            set_array    => 'set',
            insert_array => 'insert',
            get_array    => 'get',
        },
    );
}

{
    my $bar = Bar->new( array => [qw( a b c )] );

    $bar->push_array('d');

    is( $bar->get_array(3)->thing, 'd', 'push coerces the array' );

    $bar->set_array( 3 => 'e' );

    is( $bar->get_array(3)->thing, 'e', 'set coerces the new member' );

    $bar->insert_array( 3 => 'f' );

    is( $bar->get_array(3)->thing, 'f', 'insert coerces the new member' );
}

{
    package Baz;
    use Moose;
    use Moose::Util::TypeConstraints;

    subtype 'SmallArrayRef'
        => as 'ArrayRef'
        => where { @{$_} <= 2 };

    coerce 'SmallArrayRef'
        => from 'ArrayRef'
        => via { [ @{$_}[ -2, -1 ] ] };

    has array => (
        traits  => ['Array'],
        is      => 'rw',
        isa     => 'SmallArrayRef',
        coerce  => 1,
        handles => {
            push_array   => 'push',
            set_array    => 'set',
            insert_array => 'insert',
        },
    );
}

{
    my $baz = Baz->new( array => [ 1, 2, 3 ] );

    is_deeply(
        $baz->array, [ 2, 3 ],
        'coercion truncates array ref in constructor'
    );

    $baz->push_array(4);

    is_deeply(
        $baz->array, [ 3, 4 ],
        'coercion truncates array ref on push'
    );

    $baz->insert_array( 1 => 5 );

    is_deeply(
        $baz->array, [ 5, 4 ],
        'coercion truncates array ref on insert'
    );

    $baz->push_array( 7, 8, 9 );

    is_deeply(
        $baz->array, [ 8, 9 ],
        'coercion truncates array ref on push'
    );
}

done_testing;
