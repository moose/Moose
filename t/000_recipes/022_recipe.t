#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;

BEGIN {
    use_ok('Moose');           
}

## attribute trait example
{

    package MyApp::Meta::Attribute::Trait::Labeled;
    use Moose::Role;

    has label => (
        is        => 'rw',
        isa       => 'Str',
        predicate => 'has_label',
    );

    package Moose::Meta::Attribute::Custom::Trait::Labeled;
    sub register_implementation { 'MyApp::Meta::Attribute::Trait::Labeled' }

    package MyApp::Website;
    use Moose;

    has url => (
        traits => [qw/Labeled/],
        isa    => 'Str',
        is     => 'rw',
        label  => "The site's URL",
    );

    has name => (
        is  => 'rw',
        isa => 'Str',
    );

    sub dump {
        my $self = shift;

        my $dump_value = '';
        
        # iterate over all the attributes in $self
        my %attributes = %{ $self->meta->get_attribute_map };
        foreach my $name (sort keys %attributes) {
    
            my $attribute = $attributes{$name};
            
            # print the label if available
            if ($attribute->does('MyApp::Meta::Attribute::Trait::Labeled')
                && $attribute->has_label) {
                    $dump_value .= $attribute->label;
            }
            # otherwise print the name
            else {
                $dump_value .= $name;
            }

            # print the attribute's value
            my $reader = $attribute->get_read_method;
            $dump_value .= ": " . $self->$reader . "\n";
        }
        
        return $dump_value;
    }

}

my $app = MyApp::Website->new(url => "http://google.com", name => "Google");
is($app->dump, q{name: Google
The site's URL: http://google.com
}, '... got the expected dump value');



