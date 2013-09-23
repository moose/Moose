package Moose::Exception::RequiredMethodsNotImplementedByClass;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Class', 'Moose::Exception::Role::Role';

has 'missing_methods' => (
    traits     => ['Array'],
    is         => 'ro',
    isa        => 'ArrayRef[Moose::Meta::Role::Method::Required]',
    auto_deref => 1,
    handles    => { method_count    => 'count',
		    get_method_at   => 'get',
		    get_all_methods => 'elements',
    },
    required   => 1
);

sub _build_message {
    my $self = shift;

    my $noun = $self->method_count == 1 ? 'method' : 'methods';
    my $list = Moose::Util::english_list( map { q{'} . $_ . q{'} } $self->get_all_methods );
    my ($role_name, $class_name) = ($self->role_name, $self->class_name);

    return "'$role_name' requires the $noun $list "
        . "to be implemented by '$class_name'";
}

1;
