package Moose::Meta::Attribute::Native::Trait::Code;
use Moose::Role;
use Moose::Meta::Attribute::Native::MethodProvider::Code;

our $VERSION   = '0.87';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

with 'Moose::Meta::Attribute::Native::Trait';

has method_provider => (
    is        => 'ro',
    isa       => 'ClassName',
    predicate => 'has_method_provider',
    default   => 'Moose::Meta::Attribute::Native::MethodProvider::Code',
);

sub _default_is { 'ro' }
sub _helper_type { 'CodeRef' }

no Moose::Role;

1;
