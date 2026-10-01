use strict;
use warnings;

use Test::More 0.96;

use Moose;

use Class::MOP::Class;
use Moose::Meta::Class;
use Moose::Meta::Attribute;

# Detect the line number reporting behaviour of this version of perl
our $use_block_end;
BEGIN {
    sub X { my (undef, undef, $line) = caller;
                $use_block_end++ if ($line != shift); }
    X __LINE__, # $use_block_end = 0
    sub { }     # $use_block_end = 1
};


my %tests = (
    'Class::MOP::Class superclasses attribute' => {
        attribute => Class::MOP::Class->meta->find_attribute_by_name('superclasses'),
        package   => 'Class::MOP',
        file      => $INC{'Class/MOP.pm'},

        # This is obviously pretty fragile, so let's not test the line for
        # more than one attribute.
        line => ($use_block_end ? 308 : 298),
    },
    'Moose::Meta::Class roles attribute' => {
        attribute => Moose::Meta::Class->meta->find_attribute_by_name('roles'),
        package   => 'Moose::Meta::Class',
        file      => $INC{'Moose/Meta/Class.pm'},
    },
    'Moose::Meta::Attribute required attribute' => {
        attribute => Moose::Meta::Attribute->meta->find_attribute_by_name('required'),
        package   => 'Moose::Meta::Mixin::AttributeCore',
        file      => $INC{'Moose/Meta/Mixin/AttributeCore.pm'},
    },
);

for my $subtest ( sort keys %tests ) {
    my $t = $tests{$subtest};
    subtest(
        $subtest,
        sub {
            my $c = $t->{attribute}->definition_context;
            is( $c->{package}, $t->{package}, 'package' );
            is( $c->{file},    $t->{file},    'file' );
            if ( exists $t->{line} ) {
                is( $c->{line}, $t->{line}, 'line' );
            }
        }
    );
}

done_testing;
