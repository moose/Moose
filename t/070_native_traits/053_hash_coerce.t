use strict;
use warnings;

use Test::More;
use Test::Exception;

{

    package Foo;
    use Moose;
    use Moose::Util::TypeConstraints;

    subtype 'UCHash', as 'HashRef[Str]', where {
        !grep {/[a-z]/} values %{$_};
    };

    coerce 'UCHash', from 'HashRef[Str]', via {
        $_ = uc $_ for values %{$_};
        $_;
    };

    has hash => (
        traits  => ['Hash'],
        is      => 'rw',
        isa     => 'UCHash',
        coerce  => 1,
        handles => {
            set_key => 'set',
        },
    );

    our @TriggerArgs;

    has lazy => (
        traits  => ['Hash'],
        is      => 'rw',
        isa     => 'UCHash',
        coerce  => 1,
        lazy    => 1,
        default => sub { { x => 'a' } },
        handles => {
            set_lazy => 'set',
        },
        trigger => sub { @TriggerArgs = @_ },
        clearer => 'clear_lazy',
    );
}

my $foo = Foo->new;

{
    $foo->hash( { x => 'A', y => 'B' } );

    $foo->set_key( z => 'c' );

    is_deeply(
        $foo->hash, { x => 'A', y => 'B', z => 'C' },
        'set coerces the hash'
    );
}

{
    $foo->set_lazy( y => 'b' );

    is_deeply(
        $foo->lazy, { x => 'A', y => 'B' },
        'set coerces the hash - lazy'
    );

    is_deeply(
        \@Foo::TriggerArgs,
        [ $foo, { x => 'A', y => 'B' }, { x => 'A' } ],
        'trigger receives expected arguments'
    );
}

done_testing;
