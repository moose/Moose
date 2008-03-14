#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;
use Test::Exception;
use Test::Moose;

BEGIN {
    use_ok('Moose');
}

{
    package My::Attribute::Trait;
    use Moose::Role;
    
    has 'alias_to' => (is => 'ro', isa => 'Str');
    
    after 'install_accessors' => sub {
        my $self = shift;
        $self->associated_class->add_method(
            $self->alias_to, 
            $self->get_read_method_ref
        );
    };
}

{
    package My::Class;
    use Moose;
    
    has 'bar' => (
        traits   => [qw/My::Attribute::Trait/],
        is       => 'ro',
        isa      => 'Int',
        alias_to => 'baz',
    );
    
    has 'gorch' => (
        is      => 'ro',
        isa     => 'Int',
        default => sub { 10 }
    );    
}

my $c = My::Class->new(bar => 100);
isa_ok($c, 'My::Class');

is($c->bar, 100, '... got the right value for bar');
is($c->gorch, 10, '... got the right value for gorch');

can_ok($c, 'baz');
is($c->baz, 100, '... got the right value for baz');

does_ok($c->meta->get_attribute('bar'), 'My::Attribute::Trait');

ok(!$c->meta->get_attribute('gorch')->does('My::Attribute::Trait'), '... gorch doesnt do the trait');



