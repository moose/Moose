package Moose::Deprecated;

use strict;
use warnings;

our $VERSION = '1.14';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Package::DeprecationManager -deprecations => {
    'coerce without coercion' => '1.08',
    'pre-0.94 MetaRole API'   => '0.94',
    'alias or excludes'       => '0.89',
    'Role type'               => '0.84',
    'subtype without sugar'   => '0.72',
    'type without sugar'      => '0.72',
    'Moose::init_meta'        => '0.56',
    },
    -ignore => [
    qw( Moose
        Moose::Exporter
        Moose::Meta::Attribute
        Moose::Meta::Class
        Moose::Util::MetaRole
        )
    ],
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

=head1 AUTHORS

Dave Rolsky E<lt>autarch@urth.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2010 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
