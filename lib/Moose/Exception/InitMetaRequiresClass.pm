package Moose::Exception::InitMetaRequiresClass;
our $VERSION = '3.0000';

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::ParamsHash';

sub _build_message {
    "Cannot call init_meta without specifying a for_class";
}

__PACKAGE__->meta->make_immutable;
1;
