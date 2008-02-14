#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 55;
use Test::Exception;

BEGIN
{
    use_ok('Moose');
}

{
    package Foo;
    use Moose;
    use Moose::Util::TypeConstraints;

    use Scalar::Util ();

    type Number
        => where { defined($_) && !ref($_) && Scalar::Util::looks_like_number($_) };

    type String
        => where { defined($_) && !ref($_) && !Scalar::Util::looks_like_number($_) };

    has vUndef   => ( is => 'rw', isa => 'Undef'   );
    has vDefined => ( is => 'rw', isa => 'Defined' );
    has vInt     => ( is => 'rw', isa => 'Int'     );
    has vNumber  => ( is => 'rw', isa => 'Number'  );
    has vStr     => ( is => 'rw', isa => 'Str'     );
    has vString  => ( is => 'rw', isa => 'String'  );

    has v_lazy_Undef   => ( is => 'rw', lazy => 1,  default => sub { undef }, isa => 'Undef'   );
    has v_lazy_Defined => ( is => 'rw', lazy => 1,  default => sub { undef }, isa => 'Defined' );
    has v_lazy_Int     => ( is => 'rw', lazy => 1,  default => sub { undef }, isa => 'Int'     );
    has v_lazy_Number  => ( is => 'rw', lazy => 1,  default => sub { undef }, isa => 'Number'  );
    has v_lazy_Str     => ( is => 'rw', lazy => 1,  default => sub { undef }, isa => 'Str'     );
    has v_lazy_String  => ( is => 'rw', lazy => 1,  default => sub { undef }, isa => 'String'  );
}

#    EXPORT TYPE CONSTRAINTS
#
Moose::Util::TypeConstraints->export_type_constraints_as_functions;

ok( Undef(undef),   '... undef is a Undef');
ok(!Defined(undef), '... undef is NOT a Defined');
ok(!Int(undef),     '... undef is NOT a Int');
ok(!Number(undef),  '... undef is NOT a Number');
ok(!Str(undef),     '... undef is NOT a Str');
ok(!String(undef),  '... undef is NOT a String');
    
ok(!Undef(5),  '... 5 is a NOT a Undef');
ok(Defined(5), '... 5 is a Defined');
ok(Int(5),     '... 5 is a Int');
ok(Number(5),  '... 5 is a Number');
ok(Str(5),     '... 5 is a Str');   
ok(!String(5), '... 5 is NOT a String');
    
ok(!Undef(0.5),  '... 0.5 is a NOT a Undef');
ok(Defined(0.5), '... 0.5 is a Defined');
ok(!Int(0.5),    '... 0.5 is NOT a Int');
ok(Number(0.5),  '... 0.5 is a Number');
ok(Str(0.5),     '... 0.5 is a Str');
ok(!String(0.5), '... 0.5 is NOT a String');
    
ok(!Undef('Foo'),  '... "Foo" is NOT a Undef');
ok(Defined('Foo'), '... "Foo" is a Defined');
ok(!Int('Foo'),    '... "Foo" is NOT a Int');
ok(!Number('Foo'), '... "Foo" is NOT a Number');
ok(Str('Foo'),     '... "Foo" is a Str');
ok(String('Foo'),  '... "Foo" is a String');


my $foo = Foo->new;

lives_ok { $foo->vUndef(undef) } '... undef is a Foo->Undef';
dies_ok { $foo->vDefined(undef) } '... undef is NOT a Foo->Defined';
dies_ok { $foo->vInt(undef) } '... undef is NOT a Foo->Int';        
dies_ok { $foo->vNumber(undef) } '... undef is NOT a Foo->Number';  
dies_ok { $foo->vStr(undef) } '... undef is NOT a Foo->Str';        
dies_ok { $foo->vString(undef) } '... undef is NOT a Foo->String';  

dies_ok { $foo->vUndef(5) } '... 5 is NOT a Foo->Undef';
lives_ok { $foo->vDefined(5) } '... 5 is a Foo->Defined';
lives_ok { $foo->vInt(5) } '... 5 is a Foo->Int';
lives_ok { $foo->vNumber(5) } '... 5 is a Foo->Number';
lives_ok { $foo->vStr(5) } '... 5 is a Foo->Str';   
dies_ok { $foo->vString(5) } '... 5 is NOT a Foo->String';

dies_ok { $foo->vUndef(0.5) } '... 0.5 is NOT a Foo->Undef';
lives_ok { $foo->vDefined(0.5) } '... 0.5 is a Foo->Defined';
dies_ok { $foo->vInt(0.5) } '... 0.5 is NOT a Foo->Int';
lives_ok { $foo->vNumber(0.5) } '... 0.5 is a Foo->Number';
lives_ok { $foo->vStr(0.5) } '... 0.5 is a Foo->Str';
dies_ok { $foo->vString(0.5) } '... 0.5 is NOT a Foo->String';

dies_ok { $foo->vUndef('Foo') } '... "Foo" is NOT a Foo->Undef';
lives_ok { $foo->vDefined('Foo') } '... "Foo" is a Foo->Defined';
dies_ok { $foo->vInt('Foo') } '... "Foo" is NOT a Foo->Int';
dies_ok { $foo->vNumber('Foo') } '... "Foo" is NOT a Foo->Number';
lives_ok { $foo->vStr('Foo') } '... "Foo" is a Foo->Str';
lives_ok { $foo->vString('Foo') } '... "Foo" is a Foo->String';

# the lazy tests 

lives_ok { $foo->v_lazy_Undef() } '... undef is a Foo->Undef';
dies_ok { $foo->v_lazy_Defined() } '... undef is NOT a Foo->Defined';
dies_ok { $foo->v_lazy_Int() } '... undef is NOT a Foo->Int';        
dies_ok { $foo->v_lazy_Number() } '... undef is NOT a Foo->Number';  
dies_ok { $foo->v_lazy_Str() } '... undef is NOT a Foo->Str';        
dies_ok { $foo->v_lazy_String() } '... undef is NOT a Foo->String';  




