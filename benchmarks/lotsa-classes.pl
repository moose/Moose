#!/usr/bin/env perl

use warnings FATAL => 'all';
use strict;
use File::Temp;
use Path::Class;
use String::TT qw(tt strip);

my $number_of_classes = shift || 1500;
my $t = shift || File::Temp->newdir;
my $tmp = dir($t);
$tmp->rmtree;
$tmp->mkpath;
(-d $tmp) or die "not a dir: $tmp";
#print "$tmp\n";

my %class_writer = (
    'Moose' => sub {
        my $name = shift;
        return strip tt q{
            package [% name %];
            use Moose;
            has 'x' => ( is => 'ro', isa => 'Str' );
            __PACKAGE__->meta->make_immutable;
            1;
            __END__
        };
    },
    'Moo' => sub {
        my $name = shift;
        return strip tt q{
            package [% name %];
            use Moo;
            has 'x' => ( is => 'ro', isa => 'Str' );
            1;
            __END__
        };
    },
    'Mo' => sub {
        my $name = shift;
        return strip tt q{
            package [% name %];
            use Mo;
            has 'x' => ( is => 'ro', isa => 'Str' );
            1;
            __END__
        };
    },
    'Mouse' => sub {
        my $name = shift;
        return strip tt q{
            package [% name %];
            use Mouse;
            has 'x' => ( is => 'ro', isa => 'Str' );
            __PACKAGE__->meta->make_immutable;
            1;
            __END__
        };
    },
    'plain-package' => sub {
        my $name = shift;
        return strip tt q{
            package [% name %];
            sub x {}
            1;
            __END__
        };
    },
);

my $class_prefix = 'TmpClassThingy';
my %lib_map;
for my $module (sort keys %class_writer) {
    my $lib = $tmp->subdir($module . '-lib');
    $lib->mkpath;
    my $all_fh = $lib->file('All.pm')->openw;
    for my $n (1 .. $number_of_classes) {
        my $class_name = $class_prefix . $n;
        my $fh = $lib->file($class_name . '.pm')->openw;
        $fh->say($class_writer{$module}->($class_name)) or die;
        $fh->close or die;
        $all_fh->say("use $class_name;");
    }
    $all_fh->say('1;');
    $all_fh->close or die;
    $lib_map{$module} = $lib;
}

#$DB::single = 1;
for my $module (sort keys %lib_map) {
    my $lib = $lib_map{$module};
    print "$module\n";
    my $cmd = "time -p $^X -I$lib -MAll -e '1'";
    `$cmd > /dev/null 2>&1`; # to cache
#    print "$cmd\n";
    system($cmd);
    print "\n";
}

