use strict;
use warnings;

# RT 123299

use Test::More;
use Test::Fatal;

{
    package String::Object;

    use overload '""' => \&as_string, fallback => 1;

    sub new {
        my $self = bless {}, __PACKAGE__;
    }

    sub as_string { 'successful exception' }

    package Bad::Moose::Types;

    use Moose;
    use MooseX::Types::Moose qw( Str );
    use MooseX::Types -declare => [ 'AlwaysFail', 'StringObject' ];

    subtype AlwaysFail,
        as Str,
        where { 0 },
        message { String::Object->new };

    class_type StringObject, { class => 'String::Object' };
    coerce Str, from StringObject, via { 'coerced' };

    package Bad::Moose;
    use Moose;

    has validation_fail => (
        is         => 'ro',
        isa        => Bad::Moose::Types::AlwaysFail,
    );

    __PACKAGE__->meta->make_immutable; # This is the key line
}

package main;

like(
    exception { Bad::Moose->new( validation_fail => '123' ) },
    qr/successful exception/,
    "Moose type constraints accept stringifiable type constraint errors"
);

done_testing();
