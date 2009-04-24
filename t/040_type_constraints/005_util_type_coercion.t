#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 26;
use Test::Exception;

BEGIN {
	use_ok('Moose::Util::TypeConstraints');
}

{
    package HTTPHeader;
    use Moose;
    
    has 'array' => (is => 'ro');
    has 'hash'  => (is => 'ro');    
}

subtype Header => 
    => as Object 
    => where { $_->isa('HTTPHeader') };
    
coerce Header 
    => from ArrayRef 
        => via { HTTPHeader->new(array => $_[0]) }
    => from HashRef 
        => via { HTTPHeader->new(hash => $_[0]) };

        
Moose::Util::TypeConstraints->export_type_constraints_as_functions();        
        
my $header = HTTPHeader->new();
isa_ok($header, 'HTTPHeader');

ok(Header($header), '... this passed the type test');
ok(!Header([]), '... this did not pass the type test');
ok(!Header({}), '... this did not pass the type test');

my $anon_type = subtype Object => where { $_->isa('HTTPHeader') };

lives_ok {
    coerce $anon_type
        => from ArrayRef 
            => via { HTTPHeader->new(array => $_[0]) }
        => from HashRef 
            => via { HTTPHeader->new(hash => $_[0]) };
} 'coercion of anonymous subtype succeeds';

foreach my $coercion (
    find_type_constraint('Header')->coercion,
    $anon_type->coercion
    ) {

    isa_ok($coercion, 'Moose::Meta::TypeCoercion');
    
    {
        my $coerced = $coercion->coerce([ 1, 2, 3 ]);
        isa_ok($coerced, 'HTTPHeader');
    
        is_deeply(
            $coerced->array(),
            [ 1, 2, 3 ],
            '... got the right array');
        is($coerced->hash(), undef, '... nothing assigned to the hash');        
    }
    
    {
        my $coerced = $coercion->coerce({ one => 1, two => 2, three => 3 });
        isa_ok($coerced, 'HTTPHeader');
        
        is_deeply(
            $coerced->hash(),
            { one => 1, two => 2, three => 3 },
            '... got the right hash');
        is($coerced->array(), undef, '... nothing assigned to the array');        
    }
    
    {
        my $scalar_ref = \(my $var);
        my $coerced = $coercion->coerce($scalar_ref);
        is($coerced, $scalar_ref, '... got back what we put in');
    }
    
    {
        my $coerced = $coercion->coerce("Foo");
        is($coerced, "Foo", '... got back what we put in');
    }
}

subtype 'MyHashRef'
    => as 'HashRef'
    => where { $_->{is_awesome} };

coerce 'MyHashRef'
    => from 'HashRef'
    => via { $_->{my_hash_ref} };

my $tc = find_type_constraint('MyHashRef');
is_deeply(
    $tc->coerce({ my_hash_ref => { is_awesome => 1 } }),
    { is_awesome => 1 },
    "coercion runs on HashRef (not MyHashRef)",
);
is_deeply(
    $tc->coerce({ is_awesome => 1 }),
    { is_awesome => 1 },
    "did not coerce MyHashRef",
);
