use strict;
use warnings;

use Test::More;
use Test::Exception;

use Moose::Meta::TypeConstraint;
use Moose::Util::TypeConstraints;


TODO:
{
    local $TODO = 'type names are not validated in the TC metaclass';

    throws_ok { Moose::Meta::TypeConstraint->new( name => 'Foo-Bar' ) }
    qr/contains invalid characters/,
        'Type names cannot contain a dash';
}

lives_ok { Moose::Meta::TypeConstraint->new( name => 'Foo.Bar::Baz' ) }
'Type names can contain periods and colons';

throws_ok { subtype 'Foo-Baz' => as 'Item' }
qr/contains invalid characters/,
    'Type names cannot contain a dash (via subtype sugar)';

lives_ok { subtype 'Foo.Bar::Baz' => as 'Item' }
'Type names can contain periods and colons (via subtype sugar)';

is( Moose::Util::TypeConstraints::find_or_parse_type_constraint('ArrayRef[In-valid]'),
    undef,
    'find_or_parse_type_constraint returns undef on an invalid name' );

is( Moose::Util::TypeConstraints::find_or_parse_type_constraint('ArrayRef[Va.lid]'),
    'ArrayRef[Va.lid]',
    'find_or_parse_type_constraint returns name for valid name' );

done_testing;
