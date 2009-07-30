package Moose::Meta::Attribute::Trait::Native::MethodProvider::Code;
use Moose::Role;

our $VERSION   = '0.87';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

sub execute : method {
    my ( $attr, $reader, $writer ) = @_;
    return sub { $reader->(@_)->(@_) };
}

no Moose::Role;

1;
