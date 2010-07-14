package Moose::Deprecated;

use strict;
use warnings;

our $VERSION = '1.08';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Package::DeprecationManager -deprecations => {
    'pre-0.94 MetaRole API'       => '0.93',
    'Moose::Exporter with_caller' => '0.89',
    'Role type'                   => '0.84',
    'subtype without sugar'       => '0.72',
    'type without sugar'          => '0.72',
    'Moose::init_meta'            => '0.56',
    },
    -ignore => [qw( Moose Moose::Exporter Moose::Util::MetaRole )],
    ;

1;
