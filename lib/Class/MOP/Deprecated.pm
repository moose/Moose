package Class::MOP::Deprecated;

use strict;
use warnings;

use Package::DeprecationManager -deprecations => {
    'Class::MOP::load_class'                => '2.0200',
    'Class::MOP::load_first_existing_class' => '2.0200',
    'Class::MOP::is_class_loaded'           => '2.0200',
};

1;

__END__

=pod

=head1 NAME 

Class::MOP::Deprecated - Manages deprecation warnings for Class::MOP

=head1 DESCRIPTION

    use Class::MOP::Deprecated -api_version => $version;

=head1 FUNCTIONS

This module manages deprecation warnings for features that have been
deprecated in Class::MOP.

If you specify C<< -api_version => $version >>, you can use deprecated features
without warnings. Note that this special treatment is limited to the package
that loads C<Class::MOP::Deprecated>.

=cut
