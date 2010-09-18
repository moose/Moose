#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Moose 'does_ok';

my $uc;
{
    package MyHomePage;
    use Moose;

    has 'string' => (
        traits  => ['String'],
        is      => 'rw',
        isa     => 'Str',
        default => sub {''},
        handles => {
            inc_string     => 'inc',
            append_string  => 'append',
            prepend_string => 'prepend',
            match_string   => 'match',
            replace_string => 'replace',
            chop_string    => 'chop',
            chomp_string   => 'chomp',
            clear_string   => 'clear',
            length_string  => 'length',
            exclaim        => [ append => '!' ],
            capitalize_last => [ replace => qr/(.)$/, ($uc = sub { uc $1 }) ],
            invalid_number => [ match => qr/\D/ ],
        },
    );
}

my $page = MyHomePage->new();
isa_ok( $page, 'MyHomePage' );

is( $page->string, '', '... got the default value' );
is( $page->length_string, 0,'... length is zero' );

$page->string('a');
is( $page->length_string, 1,'... new string has length of one' );

$page->inc_string;
is( $page->string, 'b', '... got the incremented value' );

$page->inc_string;
is( $page->string, 'c', '... got the incremented value (again)' );

$page->append_string("foo$/");
is( $page->string, "cfoo$/", 'appended to string' );

$page->chomp_string;
is( $page->string, "cfoo", 'chomped string' );

$page->chomp_string;
is( $page->string, "cfoo", 'chomped is noop' );

$page->chop_string;
is( $page->string, "cfo", 'chopped string' );

$page->prepend_string("bar");
is( $page->string, 'barcfo', 'prepended to string' );

is_deeply( [ $page->match_string(qr/([ao])/) ], ["a"], "match" );

$page->replace_string( qr/([ao])/, sub { uc($1) } );
is( $page->string, 'bArcfo', "substitution" );
is( $page->length_string, 6, 'right length' );

$page->exclaim;
is( $page->string, 'bArcfo!', 'exclaim!' );

$page->string('Moosex');
$page->capitalize_last;
is( $page->string, 'MooseX', 'capitalize last' );

$page->string('1234');
ok( !$page->invalid_number, 'string "isn\'t an invalid number' );

$page->string('one two three four');
ok( $page->invalid_number, 'string an invalid number' );

$page->clear_string;
is( $page->string, '', "clear" );

# check the meta ..

my $string = $page->meta->get_attribute('string');
does_ok( $string, 'Moose::Meta::Attribute::Native::Trait::String' );

is(
    $string->type_constraint->name, 'Str',
    '... got the expected type constraint'
);

is_deeply(
    $string->handles,
    {
        inc_string      => 'inc',
        append_string   => 'append',
        prepend_string  => 'prepend',
        match_string    => 'match',
        replace_string  => 'replace',
        chop_string     => 'chop',
        chomp_string    => 'chomp',
        clear_string    => 'clear',
        length_string   => 'length',
        exclaim         => [ append => '!' ],
        capitalize_last => [ replace => qr/(.)$/, $uc ],
        invalid_number => [ match => qr/\D/ ],
    },
    '... got the right handles methods'
);

done_testing;
