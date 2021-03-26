use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
  package Moose::Test::StringThing;

  sub new {
    my ($class, $string) = @_;
    return bless { string => $string }, $class;
  }

  sub string_val { $_[0]{string} }
}

{
  package Moose::Test::RefThing;

  sub new {
    my ($class, $ref) = @_;
    return bless { ref => $ref }, $class;
  }

  sub string_val { ${ $_[0]{ref} } }
}

{
    package Moose::Test::Thing;
    use Moose;
    use Moose::Util::TypeConstraints;

    our $VERSION = '0.01';

    # create subtype for Moose::Test::StringThing

    subtype 'Moose::Test::StringThing'
        => as 'Object'
        => where { $_->isa('Moose::Test::StringThing') };

    coerce 'Moose::Test::StringThing'
        => from 'Str'
            => via { Moose::Test::StringThing->new($_) };

    # create subtype for Moose::Test::RefThing

    subtype 'Moose::Test::RefThing'
        => as 'Object'
        => where { $_->isa('Moose::Test::RefThing') };

    coerce 'Moose::Test::RefThing'
        => from 'ScalarRef',
            => via { Moose::Test::RefThing->new($_) },
        => from 'HashRef',
            => via { Moose::Test::RefThing->new(\$_->{a_string}) };

    # create the alias

    subtype 'Moose::Test::StringOrRef' => as 'Moose::Test::StringThing | Moose::Test::RefThing';

    # attributes

    has 'string_or_ref' => (
        is      => 'rw',
        isa     => 'Moose::Test::StringOrRef',
        coerce  => 1,
        default => sub { Moose::Test::StringThing->new() },
    );

    sub as_string {
        my ($self) = @_;
        $self->string_or_ref->string_val;
    }
}

{
    my $thing = Moose::Test::Thing->new;
    isa_ok($thing, 'Moose::Test::Thing');

    isa_ok($thing->string_or_ref, 'Moose::Test::StringThing');

    is($thing->as_string, undef, '... got correct empty string');
}

{
    my $thing = Moose::Test::Thing->new(string_or_ref => '... this is my body ...');
    isa_ok($thing, 'Moose::Test::Thing');

    isa_ok($thing->string_or_ref, 'Moose::Test::StringThing');

    is($thing->as_string, '... this is my body ...', '... got correct string');

    is( exception {
        $thing->string_or_ref('... this is the next body ...');
    }, undef, '... this will coerce correctly' );

    isa_ok($thing->string_or_ref, 'Moose::Test::StringThing');

    is($thing->as_string, '... this is the next body ...', '... got correct string');
}

{
    my $str = '... this is my body (ref) ...';

    my $thing = Moose::Test::Thing->new(string_or_ref => \$str);
    isa_ok($thing, 'Moose::Test::Thing');

    isa_ok($thing->string_or_ref, 'Moose::Test::RefThing');

    is($thing->as_string, $str, '... got correct string');

    my $str2 = '... this is the next body (ref) ...';

    is( exception {
        $thing->string_or_ref(\$str2);
    }, undef, '... this will coerce correctly' );

    isa_ok($thing->string_or_ref, 'Moose::Test::RefThing');

    is($thing->as_string, $str2, '... got correct string');
}

{
    my $io_str = Moose::Test::StringThing->new('... this is my body (Moose::Test::StringThing) ...');

    my $thing = Moose::Test::Thing->new(string_or_ref => $io_str);
    isa_ok($thing, 'Moose::Test::Thing');

    isa_ok($thing->string_or_ref, 'Moose::Test::StringThing');
    is($thing->string_or_ref, $io_str, '... and it is the one we expected');

    is($thing->as_string, '... this is my body (Moose::Test::StringThing) ...', '... got correct string');

    my $io_str2 = Moose::Test::StringThing->new('... this is the next body (Moose::Test::StringThing) ...');

    is( exception {
        $thing->string_or_ref($io_str2);
    }, undef, '... this will coerce correctly' );

    isa_ok($thing->string_or_ref, 'Moose::Test::StringThing');
    is($thing->string_or_ref, $io_str2, '... and it is the one we expected');

    is($thing->as_string, '... this is the next body (Moose::Test::StringThing) ...', '... got correct string');
}

{
    my $hashref = { a_string => "This is a string." };

    my $thing = Moose::Test::Thing->new(string_or_ref => $hashref);
    isa_ok($thing, 'Moose::Test::Thing');

    isa_ok($thing->string_or_ref, 'Moose::Test::RefThing');
    is($thing->as_string, "This is a string.");
}

{
    my $fh = Moose::Test::RefThing->new($0);

    my $thing = Moose::Test::Thing->new(string_or_ref => $fh);
    isa_ok($thing, 'Moose::Test::Thing');

    isa_ok($thing->string_or_ref, 'Moose::Test::RefThing');
    is($thing->string_or_ref, $fh, '... and it is the one we expected');
}

{
    package Foo;

    use Moose;
    use Moose::Util::TypeConstraints;

    subtype 'Coerced' => as 'ArrayRef';
    coerce 'Coerced'
        => from 'Value'
        => via { [ $_ ] };

    has carray => (
        is     => 'ro',
        isa    => 'Coerced | Coerced',
        coerce => 1,
    );
}

{
    my $foo;
    is( exception { $foo = Foo->new( carray => 1 ) }, undef, 'Can pass non-ref value for carray' );
    is_deeply(
        $foo->carray, [1],
        'carray was coerced to an array ref'
    );

    like( exception { Foo->new( carray => {} ) }, qr/\QValidation failed for 'Coerced|Coerced' with value \E(?!undef)/, 'Cannot pass a hash ref for carray attribute, and hash ref is not coerced to an undef' );
}

done_testing;
