#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 18;
use Test::Exception;

BEGIN {
    use_ok('Moose');
}

=pod

    is => rw, writer => _foo    # turns into (reader => foo, writer => _foo)
    is => ro, writer => _foo    # turns into (reader => foo, writer => _foo) as before
    is => rw, accessor => _foo  # turns into (accessor => _foo)
    is => ro, accessor => _foo  # error, accesor is rw

=cut

sub make_class {
	my ($is, $attr, $class) = @_;

	eval "package $class; use Moose; has 'foo' => ( is => '$is', $attr => '_foo' );";

	return $@ ? die $@ : $class;
}

my $obj;
my $class;

$class = make_class('rw', 'writer', 'Test::Class::WriterRW');
ok($class, "Can define attr with rw + writer");

$obj = $class->new();

can_ok($obj, qw/foo _foo/);
lives_ok {$obj->_foo(1)} "$class->_foo is writer";
is($obj->foo(), 1, "$class->foo is reader");
dies_ok {$obj->foo(2)} "$class->foo is not writer"; # this should fail
ok(!defined $obj->_foo(), "$class->_foo is not reader"); 

$class = make_class('ro', 'writer', 'Test::Class::WriterRO');
ok($class, "Can define attr with ro + writer");

$obj = $class->new();

can_ok($obj, qw/foo _foo/);
lives_ok {$obj->_foo(1)} "$class->_foo is writer";
is($obj->foo(), 1, "$class->foo is reader");
dies_ok {$obj->foo(1)} "$class->foo is not writer";
isnt($obj->_foo(), 1, "$class->_foo is not reader");

$class = make_class('rw', 'accessor', 'Test::Class::AccessorRW');
ok($class, "Can define attr with rw + accessor");

$obj = $class->new();

can_ok($obj, qw/_foo/);
lives_ok {$obj->_foo(1)} "$class->_foo is writer";
is($obj->_foo(), 1, "$class->foo is reader");

dies_ok { make_class('ro', 'accessor', "Test::Class::AccessorRO"); } "Cant define attr with ro + accessor";

