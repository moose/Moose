#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 25;
use Test::Exception;
use Test::LongString;

BEGIN {
    use_ok('Moose');           
    use_ok('Moose::Compiler');     
    use_ok('Moose::Compiler::Moose');
    use_ok('Moose::Compiler::Perl6');    
    use_ok('Moose::Compiler::Perl5');        
}

my $c = Moose::Compiler->new(engine => Moose::Compiler::Moose->new);
isa_ok($c, 'Moose::Compiler');

can_ok($c, 'engine');
isa_ok($c->engine, 'Moose::Compiler::Moose');
ok($c->engine->does('Moose::Compiler::Engine'), '... $c->engine does Moose::Compilter::Engine');

{
    package Foo;
    use Moose;
    our $VERSION = '1.0';
    
    has 'bar' => (is => 'rw', isa => 'Bar');
    has 'baz' => (is => 'ro', does => 'Baz');
}

can_ok($c, 'compile_class');

{
    my $compiled;
    lives_ok {
        $compiled = $c->compile_class(Foo->meta);
    } '... we compiled the class successfully';
    ok(defined $compiled, '... we go something');
    is_string($compiled,
q[package Foo;
use Moose;

our $VERSION = '1.0';

has 'bar' => (is => 'rw', isa => 'Bar');
has 'baz' => (is => 'ro', does => 'Baz');

1;

__END__
],
    '... got the right compiled source');
}

lives_ok {
    $c->engine(Moose::Compiler::Perl6->new);
} '... swapped engines successfully';
isa_ok($c->engine, 'Moose::Compiler::Perl6');
ok($c->engine->does('Moose::Compiler::Engine'), '... $c->engine does Moose::Compilter::Engine');

{
    my $compiled;
    lives_ok {
        $compiled = $c->compile_class(Foo->meta);
    } '... we compiled the class successfully';
    ok(defined $compiled, '... we go something');
    is_string($compiled,
q[class Foo-1.0 {

    has Bar $bar is rw;
    has $baz is ro does Baz;

}
],
    '... got the right compiled source');
}

lives_ok {
    $c->engine(Moose::Compiler::Perl5->new);
} '... swapped engines successfully';
isa_ok($c->engine, 'Moose::Compiler::Perl5');
ok($c->engine->does('Moose::Compiler::Engine'), '... $c->engine does Moose::Compilter::Engine');

{
    my $compiled;
    lives_ok {
        $compiled = $c->compile_class(Foo->meta);
    } '... we compiled the class successfully';
    ok(defined $compiled, '... we go something');
    is_string($compiled,
q[package Foo;

use strict;
use warnings;

our $VERSION = '1.0';

sub new {
    my ($class, %params) = @_;
    my %proto = (
        'bar' => undef,
        'baz' => undef,
    );
    return bless { %proto, %params } => $class;
}

sub bar {}

sub baz {}

1;

__END__
],
    '... got the right compiled source') or diag $compiled;
}


