#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';

use Moose ();
use Moose::Util::TypeConstraints;
use NoInlineAttribute;
use Test::Exception;
use Test::More;
use Test::Moose;

{
    my %handles = (
        option_accessor  => 'accessor',
        quantity         => [ accessor => 'quantity' ],
        clear_options    => 'clear',
        num_options      => 'count',
        delete_option    => 'delete',
        is_defined       => 'defined',
        options_elements => 'elements',
        has_option       => 'exists',
        get_option       => 'get',
        has_no_options   => 'is_empty',
        key_value        => 'kv',
        set_option       => 'set',
    );

    my $name = 'Foo1';

    sub build_class {
        my %attr = @_;

        my $class = Moose::Meta::Class->create(
            $name++,
            superclasses => ['Moose::Object'],
        );

        my @traits = 'Hash';
        push @traits, 'NoInlineAttribute'
            if delete $attr{no_inline};

        $class->add_attribute(
            options => (
                traits  => \@traits,
                is      => 'ro',
                isa     => 'HashRef[Str]',
                default => sub { {} },
                handles => \%handles,
                clearer => '_clear_options',
                %attr,
            ),
        );

        return ( $class->name, \%handles );
    }
}

{
    run_tests(build_class);
    run_tests( build_class( lazy => 1, default => sub { { x => 1 } } ) );
    run_tests( build_class( trigger => sub { } ) );
    run_tests( build_class( no_inline => 1 ) );

    # Will force the inlining code to check the entire hashref when it is modified.
    subtype 'MyHashRef', as 'HashRef[Str]', where { 1 };

    run_tests( build_class( isa => 'MyHashRef' ) );

    coerce 'MyHashRef', from 'HashRef', via { $_ };

    run_tests( build_class( isa => 'MyHashRef', coerce => 1 ) );
}

sub run_tests {
    my ( $class, $handles ) = @_;

    can_ok( $class, $_ ) for sort keys %{$handles};

    with_immutable {
        my $obj = $class->new( options => {} );

        ok( $obj->has_no_options, '... we have no options' );
        is( $obj->num_options, 0, '... we have no options' );

        is_deeply( $obj->options, {}, '... no options yet' );
        ok( !$obj->has_option('foo'), '... we have no foo option' );

        lives_and {
            is(
                $obj->set_option( foo => 'bar' ),
                'bar',
                'set return single new value in scalar context'
            );
        }
        '... set the option okay';

        ok( $obj->is_defined('foo'), '... foo is defined' );

        ok( !$obj->has_no_options, '... we have options' );
        is( $obj->num_options, 1, '... we have 1 option(s)' );
        ok( $obj->has_option('foo'), '... we have a foo option' );
        is_deeply( $obj->options, { foo => 'bar' }, '... got options now' );

        lives_ok {
            $obj->set_option( bar => 'baz' );
        }
        '... set the option okay';

        is( $obj->num_options, 2, '... we have 2 option(s)' );
        is_deeply(
            $obj->options, { foo => 'bar', bar => 'baz' },
            '... got more options now'
        );

        is( $obj->get_option('foo'), 'bar', '... got the right option' );

        is_deeply(
            [ $obj->get_option(qw(foo bar)) ], [qw(bar baz)],
            "get multiple options at once"
        );

        is(
            scalar( $obj->get_option(qw( foo bar)) ), "baz",
            '... got last option in scalar context'
        );

        lives_ok {
            $obj->set_option( oink => "blah", xxy => "flop" );
        }
        '... set the option okay';

        is( $obj->num_options, 4, "4 options" );
        is_deeply(
            [ $obj->get_option(qw(foo bar oink xxy)) ],
            [qw(bar baz blah flop)], "get multiple options at once"
        );

        lives_and {
            is( scalar $obj->delete_option('bar'), 'baz',
                'delete returns deleted value' );
        }
        '... deleted the option okay';

        lives_ok {
            is_deeply(
                [ $obj->delete_option( 'oink', 'xxy' ) ],
                [ 'blah', 'flop' ],
                'delete returns all deleted values in list context'
            );
        }
        '... deleted multiple option okay';

        is( $obj->num_options, 1, '... we have 1 option(s)' );
        is_deeply(
            $obj->options, { foo => 'bar' },
            '... got more options now'
        );

        $obj->clear_options;

        is_deeply( $obj->options, {}, "... cleared options" );

        lives_ok {
            $obj->quantity(4);
        }
        '... options added okay with defaults';

        is( $obj->quantity, 4, 'reader part of curried accessor works' );

        is_deeply(
            $obj->options, { quantity => 4 },
            '... returns what we expect'
        );

        lives_ok {
            $class->new( options => { foo => 'BAR' } );
        }
        '... good constructor params';

        dies_ok {
            $obj->set_option( bar => {} );
        }
        '... could not add a hash ref where an string is expected';

        dies_ok {
            $class->new( options => { foo => [] } );
        }
        '... bad constructor params';

        is_deeply(
            [ $obj->set_option( oink => "blah", xxy => "flop" ) ],
            [ 'blah', 'flop' ],
            'set returns newly set values in order of keys provided'
        );

        my @key_value = sort { $a->[0] cmp $b->[0] } $obj->key_value;
        is_deeply(
            \@key_value,
            [
                sort { $a->[0] cmp $b->[0] }[ 'xxy', 'flop' ],
                [ 'quantity', 4 ],
                [ 'oink',     'blah' ]
            ],
            '... got the right key value pairs'
            )
            or do {
            require Data::Dumper;
            diag( Data::Dumper::Dumper( \@key_value ) );
            };

        my %options_elements = $obj->options_elements;
        is_deeply(
            \%options_elements, {
                'oink'     => 'blah',
                'quantity' => 4,
                'xxy'      => 'flop'
            },
            '... got the right hash elements'
        );

        if ( $class->meta->get_attribute('options')->is_lazy ) {
            my $obj = $class->new;

            $obj->set_option( y => 2 );

            is_deeply(
                $obj->options, { x => 1, y => 2 },
                'set_option with lazy default'
            );

            $obj->_clear_options;

            ok(
                $obj->has_option('x'),
                'key for x exists - lazy default'
            );

            $obj->_clear_options;

            ok(
                $obj->is_defined('x'),
                'key for x is defined - lazy default'
            );

            $obj->_clear_options;

            is_deeply(
                [ $obj->key_value ],
                [ [ x => 1 ] ],
                'kv returns lazy default'
            );
        }
    }
    $class;
}

done_testing;
