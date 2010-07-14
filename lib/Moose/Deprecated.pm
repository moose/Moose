package Moose::Deprecated;

use strict;
use warnings;

our $VERSION = '1.08';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Package::DeprecationManager -deprecations => {
    'pre-0.94 MetaRole API'       => '0.93',
    'Moose::Exporter with_caller' => '0.89',
    },
    -ignore => [qw( Moose Moose::Exporter Moose::Util::MetaRole )],
    ;

1;
