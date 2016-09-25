package Moose::Exception::NoDestructorClassSpecified;
our $VERSION = '2.1807';

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Class', 'Moose::Exception::Role::ParamsHash';

sub _build_message {
    "The 'inline_destructor' option is present, but no destructor class was specified";
}

1;
