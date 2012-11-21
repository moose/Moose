#!/usr/bin/perl

use strict;
use warnings;

use Test::Fatal qw(lives_ok);
use Test::More;

use Moose::Util::TypeConstraints ();

lives_ok {
	ok !Moose::Util::TypeConstraints::find_or_create_type_constraint('Int')->equals('Str');
};

lives_ok {
	ok !Moose::Util::TypeConstraints::find_or_create_type_constraint('Int')->equals('NoSuchType');
};

lives_ok {
	ok !Moose::Util::TypeConstraints::find_or_create_type_constraint('ArrayRef[Int]')->equals('ArrayRef[Str]');
};

lives_ok {
	ok !Moose::Util::TypeConstraints::find_or_create_type_constraint('ArrayRef[Int]')->equals('SomeNonType');
};

my $tc = Moose::Util::TypeConstraints::find_type_constraint('HashRef')->parameterize('Int');
lives_ok {
	ok $tc->equals('HashRef[Int]');
};

done_testing;
