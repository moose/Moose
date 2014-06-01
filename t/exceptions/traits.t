use strict;
use warnings;

use Test::More;
use Test::Fatal;

# this test taken from MooseX::ABC t/immutable.t, where it broke with Moose 2.1207

{
    package ABC;
    use Moose::Role;
    around new => sub {
        my $orig = shift;
        my $class = shift;
        my $meta = Class::MOP::class_of($class);
        $meta->throw_error("$class is abstract, it cannot be instantiated");
        $class->$orig(@_);
    };
}
{
    package MyApp::Base;
    use Moose;
    with 'ABC';
    __PACKAGE__->meta->make_immutable(inline_constructor => 0);
}


like(
    exception { MyApp::Base->new },
    qr/MyApp::Base is abstract, it cannot be instantiated/,
    'instantiating abstract classes fails',
);

done_testing;
