package Moose::Exception::UnionTakesAtleastTwoTypeNames;
our $VERSION = '2.1801';

use Moose;
extends 'Moose::Exception';

sub _build_message {
    "You must pass in at least 2 type names to make a union";
}

1;
