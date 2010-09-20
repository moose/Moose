use strict;
use warnings;

use Test::More;
use Test::Exception;

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

done_testing;
