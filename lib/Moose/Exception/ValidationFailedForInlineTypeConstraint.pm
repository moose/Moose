package Moose::Exception::ValidationFailedForInlineTypeConstraint;
our $VERSION = '2.2208';

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Class';

# An indiscriminate `use` without an import list somehow makes
# type_constraint_message a hash memory address
use Moose::Util::TypeConstraints qw(
    duck_type

    coerce
        from
        via

    subtype
        as
    );
subtype '_MooseImmediateStr' => as 'Str';
subtype '_MooseDucktypeStr'  => as duck_type([qw< ("" >]);
coerce '_MooseImmediateStr',
    from '_MooseDucktypeStr',
    via { "$_" };

has 'type_constraint_message' => (
    is       => 'ro',
    isa      => '_MooseImmediateStr',
    coerce   => 1,
    required => 1
);

has 'attribute_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has 'value' => (
    is       => 'ro',
    isa      => 'Any',
    required => 1
);

has 'new_member' => (
    is        => 'ro',
    isa       => 'Bool',
    default   => 0,
    predicate => 'is_a_new_member'
);

sub _build_message {
    my $self = shift;

    my $line1;

    if( $self->new_member ) {
        $line1 = "A new member value for ".$self->attribute_name." does not pass its type constraint because: "
    }
    else {
        $line1 = "Attribute (".$self->attribute_name.") does not pass the type constraint because: ";
    }

    return $line1 . $self->type_constraint_message;
}

__PACKAGE__->meta->make_immutable;
1;
