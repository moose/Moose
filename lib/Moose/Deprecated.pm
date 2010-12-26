package Moose::Deprecated;

use strict;
use warnings;

our $AUTHORITY = 'cpan:STEVAN';

use Package::DeprecationManager 0.07 -deprecations => {
    'default is for Native Trait'      => '1.14',
    'default default for Native Trait' => '1.14',
    'coerce without coercion'          => '1.08',
    'pre-0.94 MetaRole API'            => '0.94',
    'alias or excludes'                => '0.89',
    'Role type'                        => '0.84',
    'subtype without sugar'            => '0.72',
    'type without sugar'               => '0.72',
    'Moose::init_meta'                 => '0.56',
    },
    -ignore => [qr/^(?:Class::MOP|Moose)(?:::)?/],
    ;

1;

__END__

=pod

=head1 NAME 

Moose::Deprecated - Manages deprecation warnings for Moose

=head1 DESCRIPTION

    use Moose::Deprecated -api_version => $version;

=head1 FUNCTIONS

This module manages deprecation warnings for features that have been
deprecated in Moose.

If you specify C<< -api_version => $version >>, you can use deprecated features
without warnings. Note that this special treatment is limited to the package
that loads C<Moose::Deprecated>.

=cut
