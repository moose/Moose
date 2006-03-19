#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;

use Scalar::Util 'isweak';

BEGIN {
    use_ok('Moose');           
}

{
    package HTTPHeader;
    use strict;
    use warnings;
    use Moose;
    
    coerce 'HTTPHeader'
        => as ArrayRef 
            => to { HTTPHeader->new(array => $_[0]) }
        => as HashRef 
            => to { HTTPHeader->new(hash => $_[0]) };    
    
    has 'array' => (is => 'ro');
    has 'hash'  => (is => 'ro');    

    package Engine;
    use strict;
    use warnings;
    use Moose;
    
    has 'header' => (is => 'rw', isa => 'HTTPHeader', coerce => 1);    
}

my $engine = Engine->new();
isa_ok($engine, 'Engine');

# try with arrays

$engine->header([ 1, 2, 3 ]);
isa_ok($engine->header, 'HTTPHeader');

is_deeply(
    $engine->header->array,
    [ 1, 2, 3 ],
    '... got the right array value of the header');
ok(!defined($engine->header->hash), '... no hash value set');

# try with hash

$engine->header({ one => 1, two => 2, three => 3 });
isa_ok($engine->header, 'HTTPHeader');

is_deeply(
    $engine->header->hash,
    { one => 1, two => 2, three => 3 },
    '... got the right hash value of the header');
ok(!defined($engine->header->array), '... no array value set');

dies_ok {
   $engine->header("Foo"); 
} '... dies with the wrong type, even after coercion';

lives_ok {
   $engine->header(HTTPHeader->new); 
} '... lives with the right type, even after coercion';




