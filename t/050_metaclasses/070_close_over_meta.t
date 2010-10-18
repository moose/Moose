#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Moose;

use Class::MOP;
use List::MoreUtils 'any';
use Package::Stash;
use Scalar::Util 'blessed';
use Test::Requires 'PadWalker';

sub doesnt_close_over_meta {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $code = shift;
    my ($pkg, $name) = Class::MOP::get_code_info($code);
    my $closed_over = PadWalker::closed_over($code);
    ok(!(any { ref eq 'REF' && blessed($$_) && $$_->isa('Class::MOP::Object') }
             values %$closed_over),
       "${pkg}::${name} doesn't close over any metaobjects");
}

sub class_doesnt_close_over_meta {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $class = shift;
    my $stash = Package::Stash->new($class);
    with_immutable {
        doesnt_close_over_meta($_)
            for map { $stash->get_package_symbol('&' . $_) }
                    grep { $_ ne 'meta' }
                         $stash->list_all_package_symbols('CODE');
    } $class;
}

{
    package BasicAccessors;
    use Moose;

    has foo => (
        is        => 'ro',
        clearer   => 'clear_foo',
        predicate => 'has_foo',
    );

    has bar => (
        is => 'rw',
    );

    has baz => (
        reader => 'get_baz',
        writer => 'set_baz',
    );

    no Moose;
}

{
    package MethodModifiers::Base;
    use Moose;

    sub foo_base { }
    sub bar_base { }
    sub baz_base { }
    sub quux_base { }
    sub quuux_base { inner() };

    no Moose;
}

{
    package MethodModifiers;
    use Moose;
    extends 'MethodModifiers::Base';

    sub foo { }
    sub bar { }
    sub baz { }

    before foo => sub { };
    after  bar => sub { };
    around baz => sub { };

    before foo_base => sub { };
    after  bar_base => sub { };
    around baz_base => sub { };
    override quux_base => sub { super() };
    augment quuux_base => sub { inner() };

    no Moose;
}

{
    package ConstructorDestructor;
    use Moose;

    has def => (
        is      => 'ro',
        default => '',
    );

    has def_ref => (
        is      => 'ro',
        default => sub { [] },
    );

    has build => (
        is      => 'ro',
        builder => '_build_build',
    );

    has def_lazy => (
        is      => 'ro',
        default => '',
        lazy    => 1,
    );

    has def_ref_lazy => (
        is      => 'ro',
        default => sub { [] },
        lazy    => 1,
    );

    has build_lazy => (
        is      => 'ro',
        builder => '_build_build_lazy',
        lazy    => 1,
    );

    sub _build_build { '' }
    sub _build_build_lazy { '' }

    sub BUILD { }
    sub BUILDARGS { shift->SUPER::BUILDARGS(@_) }
    sub DEMOLISH { }

    no Moose;
}

{
    package FancyAccessors;
    use Moose;
    use Moose::Util::TypeConstraints;

    subtype 'Coerced', as 'Str', where { /a-z/ };
    coerce 'Coerced', from 'Str', via { lc };

    has foo => (
        is          => 'rw',
        isa         => 'FancyAccessors',
        weak_ref    => 1,
        initializer => sub { $_[2]->($_[1]) },
    );

    has bar => (
        is       => 'rw',
        isa      => 'Coerced',
        coerce   => 1,
        trigger  => sub { 'foo' },
        init_arg => 'rab',
    );

    has baz => (
        is            => 'ro',
        isa           => 'ArrayRef[Int]',
        auto_deref    => 1,
        required      => 1,
        documentation => "it's a baz",
    );

    no Moose;
    no Moose::Util::TypeConstraints;
}

{
    package NativeTraits;
    use Moose;

    has array => (
        traits  => ['Array'],
        isa     => 'ArrayRef',
        default => sub { [] },
        handles => {
            array_count              => 'count',
            array_elements           => 'elements',
            array_is_empty           => 'is_empty',
            array_push               => 'push',
            array_push_curried       => [ push => 42, 84 ],
            array_unshift            => 'unshift',
            array_unshift_curried    => [ unshift => 42, 84 ],
            array_pop                => 'pop',
            array_shift              => 'shift',
            array_get                => 'get',
            array_get_curried        => [ get => 1 ],
            array_set                => 'set',
            array_set_curried_1      => [ set => 1 ],
            array_set_curried_2      => [ set => ( 1, 98 ) ],
            array_accessor           => 'accessor',
            array_accessor_curried_1 => [ accessor => 1 ],
            array_accessor_curried_2 => [ accessor => ( 1, 90 ) ],
            array_clear              => 'clear',
            array_delete             => 'delete',
            array_delete_curried     => [ delete => 1 ],
            array_insert             => 'insert',
            array_insert_curried     => [ insert => ( 1, 101 ) ],
            array_splice             => 'splice',
            array_splice_curried_1   => [ splice => 1 ],
            array_splice_curried_2   => [ splice => 1, 2 ],
            array_splice_curried_all => [ splice => 1, 2, ( 3, 4, 5 ) ],
            array_sort               => 'sort',
            array_sort_curried       =>
                [ sort => ( sub { $_[1] <=> $_[0] } ) ],
            array_sort_in_place      => 'sort_in_place',
            array_sort_in_place_curried =>
                [ sort_in_place => ( sub { $_[1] <=> $_[0] } ) ],
            array_map                => 'map',
            array_map_curried        => [ map => ( sub { $_ + 1 } ) ],
            array_grep               => 'grep',
            array_grep_curried       => [ grep => ( sub { $_ < 5 } ) ],
            array_first              => 'first',
            array_first_curried      => [ first => ( sub { $_ % 2 } ) ],
            array_join               => 'join',
            array_join_curried       => [ join => '-' ],
            array_shuffle            => 'shuffle',
            array_uniq               => 'uniq',
            array_reduce             => 'reduce',
            array_reduce_curried     =>
                [ reduce => ( sub { $_[0] * $_[1] } ) ],
            array_natatime           => 'natatime',
            array_natatime_curried   => [ natatime => 2 ],
        },
    );

    has bool => (
        traits  => ['Bool'],
        isa     => 'Bool',
        default => 0,
        handles => {
            bool_illuminate  => 'set',
            bool_darken      => 'unset',
            bool_flip_switch => 'toggle',
            bool_is_dark     => 'not',
        },
    );

    has code => (
        traits  => ['Code'],
        isa     => 'CodeRef',
        default => sub { sub { } },
        handles => {
            code_execute        => 'execute',
            code_execute_method => 'execute_method',
        },
    );

    has counter => (
        traits  => ['Counter'],
        isa     => 'Int',
        default => 0,
        handles => {
            inc_counter    => 'inc',
            inc_counter_2  => [ inc => 2 ],
            dec_counter    => 'dec',
            dec_counter_2  => [ dec => 2 ],
            reset_counter  => 'reset',
            set_counter    => 'set',
            set_counter_42 => [ set => 42 ],
        },
    );

    has hash => (
        traits  => ['Hash'],
        isa     => 'HashRef',
        default => sub { {} },
        handles => {
            hash_option_accessor  => 'accessor',
            hash_quantity         => [ accessor => 'quantity' ],
            hash_clear_options    => 'clear',
            hash_num_options      => 'count',
            hash_delete_option    => 'delete',
            hash_is_defined       => 'defined',
            hash_options_elements => 'elements',
            hash_has_option       => 'exists',
            hash_get_option       => 'get',
            hash_has_no_options   => 'is_empty',
            hash_key_value        => 'kv',
            hash_set_option       => 'set',
        },
    );

    has number => (
        traits  => ['Number'],
        isa     => 'Num',
        default => 0,
        handles => {
            num_abs         => 'abs',
            num_add         => 'add',
            num_inc         => [ add => 1 ],
            num_div         => 'div',
            num_cut_in_half => [ div => 2 ],
            num_mod         => 'mod',
            num_odd         => [ mod => 2 ],
            num_mul         => 'mul',
            num_set         => 'set',
            num_sub         => 'sub',
            num_dec         => [ sub => 1 ],
        },
    );

    has string => (
        traits  => ['String'],
        isa     => 'Str',
        default => '',
        handles => {
            string_inc             => 'inc',
            string_append          => 'append',
            string_append_curried  => [ append => '!' ],
            string_prepend         => 'prepend',
            string_prepend_curried => [ prepend => '-' ],
            string_replace         => 'replace',
            string_replace_curried => [ replace => qr/(.)$/, sub { uc $1 } ],
            string_chop            => 'chop',
            string_chomp           => 'chomp',
            string_clear           => 'clear',
            string_match           => 'match',
            string_match_curried    => [ match  => qr/\D/ ],
            string_length           => 'length',
            string_substr           => 'substr',
            string_substr_curried_1 => [ substr => (1) ],
            string_substr_curried_2 => [ substr => ( 1, 3 ) ],
            string_substr_curried_3 => [ substr => ( 1, 3, 'ong' ) ],
        },
    );

    no Moose;
}

{ local $TODO = "we close over all kinds of stuff";
class_doesnt_close_over_meta('BasicAccessors');
class_doesnt_close_over_meta('MethodModifiers');
class_doesnt_close_over_meta('ConstructorDestructor');
class_doesnt_close_over_meta('FancyAccessors');
class_doesnt_close_over_meta('NativeTraits');
}

done_testing;
