#!/usr/bin/env perl
use strict;
use warnings;
use Time::HiRes 'time';
use List::Util 'sum';
use IPC::System::Simple 'system';
use autodie;
use Parse::BACKPAN::Packages;
use LWP::Simple;
use Archive::Tar;
use File::Slurp 'slurp';

my $backpan = Parse::BACKPAN::Packages->new;
my @cmops   = $backpan->distributions('Class-MOP');
my @mooses  = $backpan->distributions('Moose');

my $cmop_version = 0;
my $cmop_dir;

my $base = "http://backpan.cpan.org/";

for my $moose (@mooses) {
    my $moose_dir = build($moose);

    # Find the CMOP dependency
    my $makefile = slurp("$moose_dir/Makefile.PL");
    my ($cmop_dep) = $makefile =~ /Class::MOP.*?([0-9._]+)/
        or die "Unable to find Class::MOP version dependency in $moose_dir/Makefile.PL";

    # typo?
    $cmop_dep = '0.64_07' if $cmop_dep eq '0.6407';

    # nonexistent dev releases?
    $cmop_dep = '0.79' if $cmop_dep eq '0.78_02';
    $cmop_dep = '0.83' if $cmop_dep eq '0.82_01';

    bump_cmop($cmop_dep, $moose);

    warn "Building $moose_dir";
    eval {
        system("(cd '$moose_dir' && '$^X' '-I$cmop_dir/lib' Makefile.PL && make && sudo make install) >/dev/null");

        my @times;
        for (1 .. 5) {
            my $start = time;
            system(
                $^X,
                "-I$moose_dir/lib",
                "-I$cmop_dir/lib",
                '-e', 'package Class; use Moose;',
            );
            push @times, time - $start;
        }

        my $duration = sum(@times) / @times;
        my $mem = qx[$^X -I$moose_dir/lib -I$cmop_dir/lib -MGTop -e 'my (\$gtop, \$before); BEGIN { \$gtop = GTop->new; \$before = \$gtop->proc_mem(\$\$)->size; } package Class; use Moose; print \$gtop->proc_mem(\$\$)->size - \$before'];
        printf "%7s: %0.4f (%s), %d bytes\n",
            $moose->version,
            $duration,
            join(', ', map { sprintf "%0.4f", $_ } @times),
            $mem;
    };
    warn $@ if $@;
}

sub bump_cmop {
    my $expected = shift;
    my $moose = shift;

    return $cmop_dir if $cmop_version eq $expected;

    my @orig_cmops = @cmops;
    shift @cmops until !@cmops || $cmops[0]->version eq $expected;

    die "Ran out of cmops, wanted $expected for "
        . $moose->distvname
        . " (had " . join(', ', map { $_->version } @orig_cmops) . ")"
            if !@cmops;

    $cmop_version = $cmops[0]->version;
    $cmop_dir = build($cmops[0]);

    warn "Building $cmop_dir";
    system("(cd '$cmop_dir' && '$^X' Makefile.PL && make && sudo make install) >/dev/null");

    return $cmop_dir;
}

sub build {
    my $dist = shift;
    my $distvname = $dist->distvname;
    return $distvname if -d $distvname;

    warn "Downloading $distvname";
    my $tarball = get($base . $dist->prefix);
    open my $handle, '<', \$tarball;

    my $tar = Archive::Tar->new;
    $tar->read($handle);
    $tar->extract;

    my ($arbitrary_file) = $tar->list_files;
    (my $directory = $arbitrary_file) =~ s{/.*}{};
    return $directory;
}

