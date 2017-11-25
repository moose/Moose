use strict;
use warnings;

use Test::Fatal;
use Test::More;

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
        handles => { map { 'hash_' . $_ => $_ } qw( accessor set ) },
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
            lazy_set => 'set',
        },
        trigger => sub { @TriggerArgs = @_ },
    );
}

my $foo = Foo->new;

subtest(
    'hash members are coerceable but hash itself is not',
    sub {
        $foo->hash( { x => 'A', y => 'B' } );

        $foo->hash_set( z => 'c' );

        is_deeply(
            $foo->hash,
            { x => 'A', y => 'B', z => 'C' },
            'set coerces the hash'
        );

        $foo->hash_accessor( v => 'd' );

        is_deeply(
            $foo->hash,
            { v => 'D', x => 'A', y => 'B', z => 'C' },
            'accessor coerces the hash'
        );

        $foo->lazy_set( y => 'b' );

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
);

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

    coerce 'Thing' => from 'Str' => via { Thing->new( thing => $_ ) };

    subtype 'HashRefOfThings' => as 'HashRef[Thing]';

    coerce 'HashRefOfThings' => from 'HashRef[Str]' => via {
        my %new;
        for my $k ( keys %{$_} ) {
            $new{$k} = Thing->new( thing => $_->{$k} );
        }
        return \%new;
    };

    coerce 'HashRefOfThings' => from 'Str' =>
        via { [ Thing->new( thing => $_ ) ] };

    has hash => (
        traits  => ['Hash'],
        is      => 'rw',
        isa     => 'HashRefOfThings',
        coerce  => 1,
        handles => {
            map { 'hash_' . $_ => $_ }
                qw( accessor clear delete exists get set )
        },
    );
}

subtest(
    'both the hash itself and the members are coerceable',
    sub {
        my $bar = Bar->new( hash => { foo => 1, bar => 2 } );

        is(
            $bar->hash_get('foo')->thing, 1,
            'constructor coerces hash reference'
        );

        $bar->hash_set( baz => 3, quux => 4 );

        is(
            $bar->hash_get('baz')->thing, 3,
            'set coerces new hash values - baz'
        );

        is(
            $bar->hash_get('quux')->thing, 4,
            'set coerces new hash values - quux'
        );

        $bar->hash_accessor( flurb => 5 );

        is(
            $bar->hash_get('flurb')->thing, 5,
            'accessor coerces new hash values'
        );

        $bar->hash_delete('flurb');
        ok(
            !$bar->hash_exists('flurb'),
            'delete works as expected with coerceable hash'
        );

        $bar->hash_clear;
        is_deeply( $bar->hash, {}, 'clear empties the hash' );
    }
);

{
    package Baz;
    use Moose;
    use Moose::Util::TypeConstraints;

    class_type 'Thing';

    has hash => (
        traits  => ['Hash'],
        is      => 'rw',
        isa     => 'HashRefOfThings',
        coerce  => 1,
        handles => {
            map { 'hash_' . $_ => $_ }
                qw( accessor clear delete exists get set )
        },
    );
}

subtest(
    'only the members are coerceable',
    sub {
        my $baz = Baz->new( hash => { foo => 1, bar => 2 } );

        is(
            $baz->hash_get('foo')->thing, 1,
            'constructor coerces hash reference'
        );

        $baz->hash_set( baz => 3, quux => 4 );

        is(
            $baz->hash_get('baz')->thing, 3,
            'set coerces new hash values - baz'
        );

        is(
            $baz->hash_get('quux')->thing, 4,
            'set coerces new hash values - quux'
        );

        $baz->hash_accessor( flurb => 5 );

        is(
            $baz->hash_get('flurb')->thing, 5,
            'accessor coerces new hash values'
        );

        $baz->hash_delete('flurb');
        ok(
            !$baz->hash_exists('flurb'),
            'delete works as expected with coerceable hash values'
        );

        $baz->hash_clear;
        is_deeply( $baz->hash, {}, 'clear empties the hash' );
    }
);

done_testing;
