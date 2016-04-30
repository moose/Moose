package Moose::Exception::AttributeIsRequired;
our $VERSION = '2.1801';

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Class';

has 'attribute_name' => (
    is            => 'ro',
    isa           => 'Str',
    required      => 1,
    documentation => "This attribute can be used for fetching attribute instance:\n".
                     "    my \$class = Moose::Util::find_meta( \$exception->class_name );\n".
                     "    my \$attribute = \$class->get_attribute( \$exception->attribute_name );\n",
);

has 'params' => (
    is        => 'ro',
    isa       => 'HashRef',
    predicate => 'has_params',
);

sub _build_message {
    my $self = shift;
    "Attribute (".$self->attribute_name.") is required";
}

1;
