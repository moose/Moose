#!perl

### MODULES

package MooseHorse;
use Moose;
has foo => (is => 'rw');
no Moose;

package MooseHorseImmut;
use Moose;
has foo => (is => 'rw');
__PACKAGE__->meta->make_immutable();
no Moose;

package MooseHorseImmutNoConst;
use Moose;
has foo => (is => 'rw');
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
no Moose;


package CAFHorse;
use warnings;
use strict;
use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(qw(foo));


package main;
use warnings;
use strict;

use Benchmark qw(cmpthese);
use Benchmark ':hireswallclock';

my $moose                = MooseHorse->new;
my $moose_immut          = MooseHorseImmut->new;
my $moose_immut_no_const = MooseHorseImmutNoConst->new;
my $caf                  = CAFHorse->new;

my $acc_rounds = 1_000_000;
my $ins_rounds = 1_000_000;

print "\nSETTING\n";
cmpthese($acc_rounds, {
    Moose               => sub { $moose->foo(23) },
    MooseImmut          => sub { $moose_immut->foo(23) },
    MooseImmutNoConst   => sub { $moose_immut_no_const->foo(23) },
    CAF                 => sub { $caf->foo(23) },
}, 'noc');

print "\nGETTING\n";
cmpthese($acc_rounds, {
    Moose               => sub { $moose->foo },
    MooseImmut          => sub { $moose_immut->foo },
    MooseImmutNoConst   => sub { $moose_immut_no_const->foo },
    CAF                 => sub { $caf->foo },
}, 'noc');

my (@moose, @moose_immut, @moose_immut_no_const, @caf_stall);
print "\nCREATION\n";
cmpthese($ins_rounds, {
    Moose             => sub { push @moose,                MooseHorse->new(foo => 23) },
    MooseImmut        => sub { push @moose_immut,          MooseHorseImmut->new(foo => 23) },
    MooseImmutNoConst => sub { push @moose_immut_no_const, MooseHorseImmutNoConst->new(foo => 23) },
    CAF               => sub { push @caf_stall,            CAFHorse->new({foo => 23}) },
}, 'noc');

my ( $moose_idx, $moose_immut_idx, $moose_immut_no_const_idx, $caf_idx ) = ( 0, 0, 0, 0 );
print "\nDESTRUCTION\n";
cmpthese($ins_rounds, {
    Moose => sub {
        $moose[$moose_idx] = undef;
        $moose_idx++;
    },
    MooseImmut => sub {
        $moose_immut[$moose_immut_idx] = undef;
        $moose_immut_idx++;
    },
    MooseImmutNoConst => sub {
        $moose_immut_no_const[$moose_immut_no_const_idx] = undef;
        $moose_immut_no_const_idx++;
    },
    CAF   => sub {
        $caf_stall[$caf_idx] = undef;
        $caf_idx++;
    },
}, 'noc');


