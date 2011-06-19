package Class::MOP::Deprecated;

use strict;
use warnings;

use Package::DeprecationManager -deprecations => {
};

package
    Class::MOP;

package
    Class::MOP::Package;

package
    Class::MOP::Module;

package
    Class::MOP::Class;

package
    Class::MOP::Instance;

package
    Class::MOP::Attribute;

package
    Class::MOP::Method::Accessor;

package
    Class::MOP::Method::Constructor;

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
