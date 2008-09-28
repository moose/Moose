#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use IO::Handle;

my @types = qw/Any Item Bool Undef Defined Value Num Int Str ClassName
               Ref ScalarRef ArrayRef HashRef CodeRef RegexpRef GlobRef
               FileHandle Object/;

my @type_values = (
    undef              => [qw/Any Item Undef Bool/],
    0                  => [qw/Any Item Defined Bool Value Num Int Str/],
    1                  => [qw/Any Item Defined Bool Value Num Int Str/],
    1.5                => [qw/Any Item Defined Value Num Str/],
    ''                 => [qw/Any Item Defined Bool Value Str/],
    't'                => [qw/Any Item Defined Value Str/],
    'f'                => [qw/Any Item Defined Value Str/],
    'undef'            => [qw/Any Item Defined Value Str/],
    'Test::More'       => [qw/Any Item Defined Value Str ClassName/],
    \undef             => [qw/Any Item Defined Ref ScalarRef/],
    \1                 => [qw/Any Item Defined Ref ScalarRef/],
    \"foo"             => [qw/Any Item Defined Ref ScalarRef/],
    [],                => [qw/Any Item Defined Ref ArrayRef/],
    [undef, \1]        => [qw/Any Item Defined Ref ArrayRef/],
    {}                 => [qw/Any Item Defined Ref HashRef/],
    sub { die }        => [qw/Any Item Defined Ref CodeRef/],
    qr/.*/             => [qw/Any Item Defined Ref RegexpRef/],
    \*main::ok         => [qw/Any Item Defined Ref GlobRef/],
    \*STDOUT           => [qw/Any Item Defined Ref GlobRef FileHandle/],
    IO::Handle->new    => [qw/Any Item Defined Ref Object FileHandle/],
    Test::Builder->new => [qw/Any Item Defined Ref Object/],
);

my %values_for_type;

for (my $i = 1; $i < @type_values; $i += 2) {
    my ($value, $valid_types) = @type_values[$i-1, $i];
    my %is_invalid = map { $_ => 1 } @types;
    delete @is_invalid{@$valid_types};

    push @{ $values_for_type{$_}{invalid} }, $value
        for grep { $is_invalid{$_} } @types;

    push @{ $values_for_type{$_}{valid} }, $value
        for grep { !$is_invalid{$_} } @types;
}

my $plan = 0;
$plan += 5 * @{ $values_for_type{$_}{valid} || [] }   for @types;
$plan += 4 * @{ $values_for_type{$_}{invalid} || [] } for @types;
$plan++; # can_ok

plan tests => $plan;

do {
    package Class;
    use Moose;

    for my $type (@types) {
        has $type => (
            is  => 'rw',
            isa => $type,
        );
    }
};

can_ok(Class => @types);

for my $type (@types) {
    for my $value (@{ $values_for_type{$type}{valid} }) {
        lives_ok {
            my $via_new = Class->new($type => $value);
            is_deeply($via_new->$type, $value, "correctly set a $type in the constructor");
        };

        lives_ok {
            my $via_set = Class->new;
            is($via_set->$type, undef, "initially unset");
            $via_set->$type($value);
            is_deeply($via_set->$type, $value, "correctly set a $type in the setter");
        };
    }

    for my $value (@{ $values_for_type{$type}{invalid} }) {
        my $display = defined($value) ? overload::StrVal($value) : 'undef';
        my $via_new;
        throws_ok {
            $via_new = Class->new($type => $value);
        } qr/Attribute \($type\) does not pass the type constraint because: Validation failed for '$type' failed with value \Q$display\E/;
        is($via_new, undef, "no object created");

        my $via_set = Class->new;
        throws_ok {
            $via_set->$type($value);
        } qr/Attribute \($type\) does not pass the type constraint because: Validation failed for '$type' failed with value \Q$display\E/;

        is($via_set->$type, undef, "value for $type not set");
    }
}

