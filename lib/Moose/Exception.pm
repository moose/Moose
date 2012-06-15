package Moose::Exception;
use Moose;
extends 'Throwable::Error';


# can't inline constructor because of Throwable::Error's API
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
no Moose;
1;

