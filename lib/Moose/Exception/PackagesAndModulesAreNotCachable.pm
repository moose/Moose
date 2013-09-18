package Moose::Exception::PackagesAndModulesAreNotCachable;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Class', 'Moose::Exception::Role::ParamsHash';

has 'package_or_module' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

sub _build_message {
    my $self = shift;
    my $package_or_module = $self->package_or_module;
    return "$package_or_module are not cacheable";
}

1;
