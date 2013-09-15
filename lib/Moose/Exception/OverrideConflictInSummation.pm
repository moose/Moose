package Moose::Exception::OverrideConflictInSummation;

use Moose;
extends 'Moose::Exception';

has 'role_application' => (
    is       => 'ro',
    isa      => 'Moose::Meta::Role::Application::RoleSummation',
    required => 1
);

has 'roles' => (
    traits   => ['Array'],
    is       => 'bare',
    isa      => 'ArrayRef[Moose::Meta::Role]',
    handles  => {
        get_roles  => 'get',
        roles      => 'elements',
        join_roles => 'join',
    },
    required => 1
);

has 'method_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has 'two_overrides_found' => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
    default  => 0
);

sub role_names {
    my $self = shift;
    my @roles = $self->roles;
    my @role_names = map { $_->name } @roles;
    return @role_names;
}

sub _build_message {
    my $self = shift;

    my @roles = $self->role_names;
    my $role_names = join "|", @roles;

    if( $self->two_overrides_found ) {
        return "We have encountered an 'override' method conflict ".
               "during composition (Two 'override' methods of the same name encountered). ".
               "This is fatal error.";
    }
    else {
        return "Role '$role_names' has encountered an 'override' method conflict " .
               "during composition (A local method of the same name has been found). This " .
               "is a fatal error." ;
    }
}

1;
