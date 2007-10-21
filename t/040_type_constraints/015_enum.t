#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 97;

use Scalar::Util ();

BEGIN {
    use_ok('Moose::Util::TypeConstraints');
}

enum Letter => 'a'..'z', 'A'..'Z';
enum Language => 'Perl 5', 'Perl 6', 'PASM', 'PIR'; # any others? ;)
enum Metacharacter => '*', '+', '?', '.', '|', '(', ')', '[', ']', '\\';

my @valid_letters = ('a'..'z', 'A'..'Z');

my @invalid_letters = qw/ab abc abcd/;
push @invalid_letters, qw/0 4 9 ~ @ $ %/;
push @invalid_letters, qw/l33t st3v4n 3num/;

my @valid_languages = ('Perl 5', 'Perl 6', 'PASM', 'PIR');
my @invalid_languages = ('Python', 'Ruby', 'Perl 666', 'PASM++');

my @valid_metacharacters = (qw/* + ? . | ( ) [ ] /, '\\');
my @invalid_metacharacters = qw/< > & % $ @ ! ~ `/;
push @invalid_metacharacters, qw/.* fish(sticks)? atreides/;
push @invalid_metacharacters, '^1?$|^(11+?)\1+$';

Moose::Util::TypeConstraints->export_type_constraints_as_functions();

ok(Letter($_), "'$_' is a letter") for @valid_letters;
ok(!Letter($_), "'$_' is not a letter") for @invalid_letters;

ok(Language($_), "'$_' is a language") for @valid_languages;
ok(!Language($_), "'$_' is not a language") for @invalid_languages;

ok(Metacharacter($_), "'$_' is a metacharacter") for @valid_metacharacters;
ok(!Metacharacter($_), "'$_' is not a metacharacter")
    for @invalid_metacharacters;

