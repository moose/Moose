#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;


{
    package HTTPHeader;
    use Moose;
    use Moose::Util::TypeConstraints;

    coerce 'HTTPHeader'
        => from ArrayRef
            => via { HTTPHeader->new(array => $_[0]) };

    coerce 'HTTPHeader'
        => from HashRef
            => via { HTTPHeader->new(hash => $_[0]) };

    has 'array' => (is => 'ro');
    has 'hash'  => (is => 'ro');

    package Engine;
    use strict;
    use warnings;
    use Moose;

    has 'header' => (is => 'rw', isa => 'HTTPHeader', coerce => 1);
}

{
    my $engine = Engine->new();
    isa_ok($engine, 'Engine');

    # try with arrays

    lives_ok {
        $engine->header([ 1, 2, 3 ]);
    } '... type was coerced without incident';
    isa_ok($engine->header, 'HTTPHeader');

    is_deeply(
        $engine->header->array,
        [ 1, 2, 3 ],
        '... got the right array value of the header');
    ok(!defined($engine->header->hash), '... no hash value set');

    # try with hash

    lives_ok {
        $engine->header({ one => 1, two => 2, three => 3 });
    } '... type was coerced without incident';
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
}

{
    my $engine = Engine->new(header => [ 1, 2, 3 ]);
    isa_ok($engine, 'Engine');

    isa_ok($engine->header, 'HTTPHeader');

    is_deeply(
        $engine->header->array,
        [ 1, 2, 3 ],
        '... got the right array value of the header');
    ok(!defined($engine->header->hash), '... no hash value set');
}

{
    my $engine = Engine->new(header => { one => 1, two => 2, three => 3 });
    isa_ok($engine, 'Engine');

    isa_ok($engine->header, 'HTTPHeader');

    is_deeply(
        $engine->header->hash,
        { one => 1, two => 2, three => 3 },
        '... got the right hash value of the header');
    ok(!defined($engine->header->array), '... no array value set');
}

{
    my $engine = Engine->new(header => HTTPHeader->new());
    isa_ok($engine, 'Engine');

    isa_ok($engine->header, 'HTTPHeader');

    ok(!defined($engine->header->hash), '... no hash value set');
    ok(!defined($engine->header->array), '... no array value set');
}

dies_ok {
    Engine->new(header => 'Foo');
} '... dies correctly with bad params';

dies_ok {
    Engine->new(header => \(my $var));
} '... dies correctly with bad params';

done_testing;
