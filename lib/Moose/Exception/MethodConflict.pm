package Moose::Exception::MethodConflict;
use Moose;
extends 'Moose::Exception';

has '+message' => (
    required => 0,
    builder  => '_build_message',
);

has consumer => (
    is       => 'ro',
    isa      => 'Moose::Meta::Class',
    required => 1,
);

has roles => (
    traits   => ['Array'],
    isa      => 'ArrayRef[RoleName]', # XXX we should have objects here
    lazy     => 1,
    default  => sub { shift->_first_method->roles },
    handles  => {
        roles => 'elements',
    },
);

has methods => (
    traits   => ['Array'],
    isa      => 'ArrayRef[Moose::Meta::Role::Method::Conflicting]',
    required => 1,
    handles  => {
        methods       => 'elements',
        _first_method => [ get => 0 ],
    },
);

sub _build_message {
    my $self = shift;

    my $class = $self->consumer;
    my @conflicts = $self->methods;
    my $conflict = $self->_first_method;
    my $roles = $conflict->roles_as_english_list;

    my @same_role_conflicts = grep { $_->roles_as_english_list eq $roles } @conflicts;

    if (@same_role_conflicts == 1) {
        return "Due to a method name conflict in roles "
               .  $roles
               . ", the method '"
               . $conflict->name
               . "' must be implemented or excluded by '"
               . $class->name
               . q{'};
    }
    else {
        my $methods
            = Moose::Util::english_list( map { q{'} . $_->name . q{'} } @same_role_conflicts );

        return "Due to method name conflicts in roles "
             .  $roles
             . ", the methods "
             . $methods
             . " must be implemented or excluded by '"
             . $class->name
             . q{'};
    }
}

1;

