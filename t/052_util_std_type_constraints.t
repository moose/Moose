#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 122;
use Test::Exception;

use Scalar::Util ();

BEGIN {
    use_ok('Moose::Util::TypeConstraints');           
}

my $SCALAR_REF = \(my $var);

Moose::Util::TypeConstraints->export_type_contstraints_as_functions();

ok(defined Any(0),               '... Any accepts anything');
ok(defined Any(100),             '... Any accepts anything');
ok(defined Any(''),              '... Any accepts anything');
ok(defined Any('Foo'),           '... Any accepts anything');
ok(defined Any([]),              '... Any accepts anything');
ok(defined Any({}),              '... Any accepts anything');
ok(defined Any(sub {}),          '... Any accepts anything');
ok(defined Any($SCALAR_REF),     '... Any accepts anything');
ok(defined Any(qr/../),          '... Any accepts anything');
ok(defined Any(bless {}, 'Foo'), '... Any accepts anything');

ok(defined Value(0),                 '... Value accepts anything which is not a Ref');
ok(defined Value(100),               '... Value accepts anything which is not a Ref');
ok(defined Value(''),                '... Value accepts anything which is not a Ref');
ok(defined Value('Foo'),             '... Value accepts anything which is not a Ref');
ok(!defined Value([]),               '... Value rejects anything which is not a Value');
ok(!defined Value({}),               '... Value rejects anything which is not a Value');
ok(!defined Value(sub {}),           '... Value rejects anything which is not a Value');
ok(!defined Value($SCALAR_REF),      '... Value rejects anything which is not a Value');
ok(!defined Value(qr/../),           '... Value rejects anything which is not a Value');
ok(!defined Value(bless {}, 'Foo'),  '... Value rejects anything which is not a Value');

ok(!defined Ref(0),               '... Ref accepts anything which is not a Value');
ok(!defined Ref(100),             '... Ref accepts anything which is not a Value');
ok(!defined Ref(''),              '... Ref accepts anything which is not a Value');
ok(!defined Ref('Foo'),           '... Ref accepts anything which is not a Value');
ok(defined Ref([]),               '... Ref rejects anything which is not a Ref');
ok(defined Ref({}),               '... Ref rejects anything which is not a Ref');
ok(defined Ref(sub {}),           '... Ref rejects anything which is not a Ref');
ok(defined Ref($SCALAR_REF),      '... Ref rejects anything which is not a Ref');
ok(defined Ref(qr/../),           '... Ref rejects anything which is not a Ref');
ok(defined Ref(bless {}, 'Foo'),  '... Ref rejects anything which is not a Ref');

ok(defined Int(0),                 '... Int accepts anything which is an Int');
ok(defined Int(100),               '... Int accepts anything which is an Int');
ok(!defined Int(''),               '... Int rejects anything which is not a Int');
ok(!defined Int('Foo'),            '... Int rejects anything which is not a Int');
ok(!defined Int([]),               '... Int rejects anything which is not a Int');
ok(!defined Int({}),               '... Int rejects anything which is not a Int');
ok(!defined Int(sub {}),           '... Int rejects anything which is not a Int');
ok(!defined Int($SCALAR_REF),      '... Int rejects anything which is not a Int');
ok(!defined Int(qr/../),           '... Int rejects anything which is not a Int');
ok(!defined Int(bless {}, 'Foo'),  '... Int rejects anything which is not a Int');

ok(!defined Str(0),                '... Str rejects anything which is not a Str');
ok(!defined Str(100),              '... Str rejects anything which is not a Str');
ok(defined Str(''),                '... Str accepts anything which is a Str');
ok(defined Str('Foo'),             '... Str accepts anything which is a Str');
ok(!defined Str([]),               '... Str rejects anything which is not a Str');
ok(!defined Str({}),               '... Str rejects anything which is not a Str');
ok(!defined Str(sub {}),           '... Str rejects anything which is not a Str');
ok(!defined Str($SCALAR_REF),      '... Str rejects anything which is not a Str');
ok(!defined Str(qr/../),           '... Str rejects anything which is not a Str');
ok(!defined Str(bless {}, 'Foo'),  '... Str rejects anything which is not a Str');

ok(!defined ScalarRef(0),                '... ScalarRef rejects anything which is not a ScalarRef');
ok(!defined ScalarRef(100),              '... ScalarRef rejects anything which is not a ScalarRef');
ok(!defined ScalarRef(''),               '... ScalarRef rejects anything which is not a ScalarRef');
ok(!defined ScalarRef('Foo'),            '... ScalarRef rejects anything which is not a ScalarRef');
ok(!defined ScalarRef([]),               '... ScalarRef rejects anything which is not a ScalarRef');
ok(!defined ScalarRef({}),               '... ScalarRef rejects anything which is not a ScalarRef');
ok(!defined ScalarRef(sub {}),           '... ScalarRef rejects anything which is not a ScalarRef');
ok(defined ScalarRef($SCALAR_REF),       '... ScalarRef accepts anything which is a ScalarRef');
ok(!defined ScalarRef(qr/../),           '... ScalarRef rejects anything which is not a ScalarRef');
ok(!defined ScalarRef(bless {}, 'Foo'),  '... ScalarRef rejects anything which is not a ScalarRef');

ok(!defined ArrayRef(0),                '... ArrayRef rejects anything which is not a ArrayRef');
ok(!defined ArrayRef(100),              '... ArrayRef rejects anything which is not a ArrayRef');
ok(!defined ArrayRef(''),               '... ArrayRef rejects anything which is not a ArrayRef');
ok(!defined ArrayRef('Foo'),            '... ArrayRef rejects anything which is not a ArrayRef');
ok(defined ArrayRef([]),                '... ArrayRef accepts anything which is a ArrayRef');
ok(!defined ArrayRef({}),               '... ArrayRef rejects anything which is not a ArrayRef');
ok(!defined ArrayRef(sub {}),           '... ArrayRef rejects anything which is not a ArrayRef');
ok(!defined ArrayRef($SCALAR_REF),      '... ArrayRef rejects anything which is not a ArrayRef');
ok(!defined ArrayRef(qr/../),           '... ArrayRef rejects anything which is not a ArrayRef');
ok(!defined ArrayRef(bless {}, 'Foo'),  '... ArrayRef rejects anything which is not a ArrayRef');

ok(!defined HashRef(0),                '... HashRef rejects anything which is not a HashRef');
ok(!defined HashRef(100),              '... HashRef rejects anything which is not a HashRef');
ok(!defined HashRef(''),               '... HashRef rejects anything which is not a HashRef');
ok(!defined HashRef('Foo'),            '... HashRef rejects anything which is not a HashRef');
ok(!defined HashRef([]),               '... HashRef rejects anything which is not a HashRef');
ok(defined HashRef({}),                '... HashRef accepts anything which is a HashRef');
ok(!defined HashRef(sub {}),           '... HashRef rejects anything which is not a HashRef');
ok(!defined HashRef($SCALAR_REF),      '... HashRef rejects anything which is not a HashRef');
ok(!defined HashRef(qr/../),           '... HashRef rejects anything which is not a HashRef');
ok(!defined HashRef(bless {}, 'Foo'),  '... HashRef rejects anything which is not a HashRef');

ok(!defined CodeRef(0),                '... CodeRef rejects anything which is not a CodeRef');
ok(!defined CodeRef(100),              '... CodeRef rejects anything which is not a CodeRef');
ok(!defined CodeRef(''),               '... CodeRef rejects anything which is not a CodeRef');
ok(!defined CodeRef('Foo'),            '... CodeRef rejects anything which is not a CodeRef');
ok(!defined CodeRef([]),               '... CodeRef rejects anything which is not a CodeRef');
ok(!defined CodeRef({}),               '... CodeRef rejects anything which is not a CodeRef');
ok(defined CodeRef(sub {}),            '... CodeRef accepts anything which is a CodeRef');
ok(!defined CodeRef($SCALAR_REF),      '... CodeRef rejects anything which is not a CodeRef');
ok(!defined CodeRef(qr/../),           '... CodeRef rejects anything which is not a CodeRef');
ok(!defined CodeRef(bless {}, 'Foo'),  '... CodeRef rejects anything which is not a CodeRef');

ok(!defined RegexpRef(0),                '... RegexpRef rejects anything which is not a RegexpRef');
ok(!defined RegexpRef(100),              '... RegexpRef rejects anything which is not a RegexpRef');
ok(!defined RegexpRef(''),               '... RegexpRef rejects anything which is not a RegexpRef');
ok(!defined RegexpRef('Foo'),            '... RegexpRef rejects anything which is not a RegexpRef');
ok(!defined RegexpRef([]),               '... RegexpRef rejects anything which is not a RegexpRef');
ok(!defined RegexpRef({}),               '... RegexpRef rejects anything which is not a RegexpRef');
ok(!defined RegexpRef(sub {}),           '... RegexpRef rejects anything which is not a RegexpRef');
ok(!defined RegexpRef($SCALAR_REF),      '... RegexpRef rejects anything which is not a RegexpRef');
ok(defined RegexpRef(qr/../),            '... RegexpRef accepts anything which is a RegexpRef');
ok(!defined RegexpRef(bless {}, 'Foo'),  '... RegexpRef rejects anything which is not a RegexpRef');

ok(!defined Object(0),                '... Object rejects anything which is not blessed');
ok(!defined Object(100),              '... Object rejects anything which is not blessed');
ok(!defined Object(''),               '... Object rejects anything which is not blessed');
ok(!defined Object('Foo'),            '... Object rejects anything which is not blessed');
ok(!defined Object([]),               '... Object rejects anything which is not blessed');
ok(!defined Object({}),               '... Object rejects anything which is not blessed');
ok(!defined Object(sub {}),           '... Object rejects anything which is not blessed');
ok(!defined Object($SCALAR_REF),      '... Object rejects anything which is not blessed');
ok(!defined Object(qr/../),           '... Object rejects anything which is not blessed');
ok(defined Object(bless {}, 'Foo'),   '... Object accepts anything which is blessed');

{
    package My::Role;
    sub does { 'fake' }
}

ok(!defined Role(0),                '... Role rejects anything which is not a Role');
ok(!defined Role(100),              '... Role rejects anything which is not a Role');
ok(!defined Role(''),               '... Role rejects anything which is not a Role');
ok(!defined Role('Foo'),            '... Role rejects anything which is not a Role');
ok(!defined Role([]),               '... Role rejects anything which is not a Role');
ok(!defined Role({}),               '... Role rejects anything which is not a Role');
ok(!defined Role(sub {}),           '... Role rejects anything which is not a Role');
ok(!defined Role($SCALAR_REF),      '... Role rejects anything which is not a Role');
ok(!defined Role(qr/../),           '... Role rejects anything which is not a Role');
ok(!defined Role(bless {}, 'Foo'),  '... Role accepts anything which is not a Role');
ok(defined Role(bless {}, 'My::Role'),  '... Role accepts anything which is not a Role');


