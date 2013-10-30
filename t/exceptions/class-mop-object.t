
use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    my $exception = exception {
        use Moose;
        Moose->throw_error("Hello, I am an exception object");
    };

    like(
        $exception,
        qr/Hello, I am an exception object/,
        "throw_error stringifies to the message");

    isa_ok(
        $exception,
        'Moose::Exception::Legacy',
        "throw_error stringifies to the message");
}

{
    BEGIN
    {
        {
            package FooRole;
            use Moose::Role;

            sub xyz {
                print "In xyz method";
            }
        }

        {
            package FooMetaclass;
            use Moose;
            with 'FooRole';
            extends 'Moose::Meta::Class';

            sub _inline_check_required_attr {
                my $self = shift;
                my ($attr) = @_;

                return unless defined $attr->init_arg;
                return unless $attr->can('is_required') && $attr->is_required;
                return if $attr->has_default || $attr->has_builder;

                return (
                    'if (!exists $params->{\'' . $attr->init_arg . '\'}) {',
                    $self->_inline_throw_error(
                        'Legacy => '.
                        'message        => "An inline error" '
                    ).';',
                    '}',
                );
            }
        }
    }
};

{
    {
        package Foo2;
        use Moose -metaclass => 'FooMetaclass';

        has 'baz' => (
            is       => 'ro',
            isa      => 'Int',
            required => 1,
        );
        __PACKAGE__->meta->make_immutable;
    }

    my $exception = exception {
        my $test1 = Foo2->new;
    };

    like(
        $exception,
        qr/An inline error/,
        "_inline_throw_error stringifies to the message");

    isa_ok(
        $exception,
        'Moose::Exception::Legacy',
        "_inline_throw_error stringifies to the message");
}

done_testing();
