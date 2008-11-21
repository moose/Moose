#!/usr/bin/env perl
use Test::More qw(no_plan);

my $package = qq{
package Test::Moose::Go::Boom;
use Moose;
use lib qw(lib);

has id => (
    isa     => 'Str',
    is      => 'ro',
    default => '019600',  # Moose doesn't quote this when inlining, an perl treats it as an octal ... and 9 isn't a valid octal
);

no Moose;

__PACKAGE__->meta->make_immutable;
};

eval $package;
$@ ? ::fail($@) : ::pass('quoted 019600 default works');
my $obj = Test::Moose::Go::Boom->new; 
::is($obj->id, '019600', 'value is still the same');

my $package2 = qq{
package Test::Moose::Go::Boom2;
use Moose;
use lib qw(lib);

has id => (
    isa     => 'Str',
    is      => 'ro',
    default => 017600,  # Moose doesn't quote this when inlining, an perl treats it as an octal ... and 9 isn't a valid octal
);

no Moose;

__PACKAGE__->meta->make_immutable;
};


eval $package2;
$@ ? ::fail($@) : ::pass('017600 octal default works');
my $obj = Test::Moose::Go::Boom2->new; 
::is($obj->id, 8064, 'value is still the same');