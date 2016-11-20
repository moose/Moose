use strict;
use warnings;

use Test::More;

use Moose;

use Class::MOP::Class;
use Moose::Meta::Class;
use Moose::Meta::Attribute;

my %tests = (
    'Class::MOP::Class superclasses attribute' => {
        attribute => Class::MOP::Class->meta->find_attribute_by_name('superclasses'),
        package   => 'Class::MOP',
        file      => $INC{'Class/MOP.pm'},

        # This is obviously pretty fragile, so let's not test the line for
        # more than one attribute.
        line => 308,
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
