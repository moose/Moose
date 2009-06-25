#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 27;
use Test::Moose 'does_ok';

BEGIN {
    use_ok('Moose::AttributeHelpers');
}

{
    package MyHomePage;
    use Moose;

    has 'string' => (
        traits    => [qw/String/],
        is        => 'rw',
        isa       => 'Str',
        default   => sub { '' },
        handles => {
                    inc_string     => 'inc',
                    append_string  => 'append',
                    prepend_string => 'prepend',
                    match_string   => 'match',
                    replace_string => 'replace',
                    chop_string    => 'chop',
                    chomp_string   => 'chomp',
                    clear_string   => 'clear',
                    exclaim         => { append  => [ '!' ]},
                    capitalize_last => { replace => [ qr/(.)$/, sub { uc $1 } ]},
                    invalid_number  => { match   => [ qr/\D/ ]},
                    shift_chars     => { substr  => sub { $_[1]->($_[0], 0, $_[2], '') } },
                   },
    );
}

my $page = MyHomePage->new();
isa_ok($page, 'MyHomePage');

is($page->string, '', '... got the default value');

$page->string('a');

$page->inc_string;
is($page->string, 'b', '... got the incremented value');

$page->inc_string;
is($page->string, 'c', '... got the incremented value (again)');

$page->append_string("foo$/");
is($page->string, "cfoo$/", 'appended to string');

$page->chomp_string;
is($page->string, "cfoo", 'chomped string');

$page->chomp_string;
is($page->string, "cfoo", 'chomped is noop');

$page->chop_string;
is($page->string, "cfo", 'chopped string');

$page->prepend_string("bar");
is($page->string, 'barcfo', 'prepended to string');

is_deeply( [ $page->match_string(qr/([ao])/) ], [ "a" ], "match" );

$page->replace_string(qr/([ao])/, sub { uc($1) });
is($page->string, 'bArcfo', "substitution");

$page->exclaim;
is($page->string, 'bArcfo!', 'exclaim!');

is($page->sub_string(2), 'rcfo!', 'substr(offset)');
is($page->sub_string(2, 2), 'rc', 'substr(offset, length)');
is($page->sub_string(2, 2, ''), 'rc', 'substr(offset, length, replacement)');
is($page->string, 'bAfo!', 'replacement got inserted');

is($page->shift_chars(2), 'bA', 'curried substr');
is($page->string, 'fo!', 'replacement got inserted');

$page->string('Moosex');
$page->capitalize_last;
is($page->string, 'MooseX', 'capitalize last');

$page->string('1234');
ok(!$page->invalid_number, 'string "isn\'t an invalid number');

$page->string('one two three four');
ok($page->invalid_number, 'string an invalid number');

$page->clear_string;
is($page->string, '', "clear");

# check the meta ..

my $string = $page->meta->get_attribute('string');
does_ok($string, 'Moose::AttributeHelpers::Trait::String');

is($string->helper_type, 'Str', '... got the expected helper type');

is($string->type_constraint->name, 'Str', '... got the expected type constraint');

is_deeply($string->handles, {
    inc_string     => 'inc',
    append_string  => 'append',
    prepend_string => 'prepend',
    match_string   => 'match',
    replace_string => 'replace',
    chop_string    => 'chop',
    chomp_string   => 'chomp',
    clear_string   => 'clear',
}, '... got the right provides methods');

