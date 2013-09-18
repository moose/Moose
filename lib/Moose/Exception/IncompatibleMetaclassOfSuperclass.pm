
package Moose::Exception::IncompatibleMetaclassOfSuperclass;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Class';

has [qw/superclass_name superclass_meta_type/] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

sub _build_message {
    my $self = shift;
    my $class_name = $self->class_name;
    my $ref_class = ref($self->class);
    my $superclass_name = $self->superclass_name;
    my $supermeta_type = $self->superclass_meta_type;

    return "The metaclass of $class_name ($ref_class)" .  
           " is not compatible with the metaclass of its superclass, " .
           "$superclass_name ($supermeta_type)";
}

1;
