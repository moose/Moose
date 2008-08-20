{
    package SomeClass;
    use Moose;
    use Moose::Util::TypeConstraints;

    subtype 'DigitSix' => as 'Num'
        => where { /^6$/ };
    subtype 'TextSix' => as 'Str'
        => where { /Six/i };
    coerce 'TextSix' 
        => from 'DigitSix' 
        => via { confess("Cannot live without 6 ($_)") unless /^6$/; 'Six' };

    has foo => ( isa => 'TextSix', coerce => 1, is => 'ro', default => 6,
        lazy => 1
    ); 
}

use Test::More tests => 2;
my $attr = SomeClass->meta->get_attribute('foo');
is($attr->get_value(SomeClass->new()), 'Six');
is(SomeClass->new()->foo, 'Six');

