package Moose::Exception;
use Moose;
extends 'Throwable::Error';



__PACKAGE__->meta->make_immutable;
no Moose;
1;

