use strict;
use warnings; 

use Test::More;
use Test::Fatal;

# ABOUT:
#
#  This test tests for unusual use of Native Types,
#  specificially, creation of 3rd Party Native types using the Core Native Types infrastructure,
#  but without having the definitions of all the accessors under the primary Moose namespace,
#  so that the only element needed under the Moose namespace is the registration node. 

BEGIN  {
    package Moose::Meta::Attribute::Custom::Trait::CustomTrait;

    sub register_implementation {
        return 'Test::Trait::CustomTrait';
    }
    $INC{'Moose/Meta/Attribute/Custom/Trait.pm'} = 1;
}

BEGIN {
    package Test::Trait::CustomTrait;

    use Moose::Role;
    with 'Moose::Meta::Attribute::Native::Trait';

    sub _native_accessor_method_prefix { 'Test::Trait::CustomTrait::Accessors' };
    sub _helper_type { 'ArrayRef' }


    no Moose::Role;
    $INC{'Test/Trait/CustomTrait.pm'} = 1;
}

BEGIN {
    package Test::Trait::CustomTrait::Accessors::example; 

    use Moose::Role;
    
    with 'Moose::Meta::Method::Accessor::Native::Reader' => { -excludes => [ _maximum_arguments =>, ] };

 
    sub _maximum_arguments { 0 }
    sub _return_value {
        my $self = shift;
        my ($slot_access) = @_;
        return '"example"';
   }

   no Moose::Role;

   $INC{'Test/Trait/CustomTrait/Accessors/example.pm'} = 1; 
}

BEGIN { 
    package Example;

    use Moose;

    has attr => ( 
        isa => 'ArrayRef',
        is  => 'rw',
        required => 1,
        traits => [qw( CustomTrait )],
        handles => {
            do_example => example =>,
        }
    );
    __PACKAGE__->meta->make_immutable;
}

is( exception { 
    my $instance = Example->new(
        attr => [ 'Not Used' ],
    );

    is( $instance->do_example, "example" , "Accessor works" );
},  undef , 'no failures');

done_testing;
1;

 
