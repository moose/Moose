
package metaclass;

use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed';
use Try::Tiny;

use Class::MOP;

sub import {
    my ( $class, @args ) = @_;

    unshift @args, "metaclass" if @args % 2 == 1;
    my %options = @args;

    my $meta_name = exists $options{meta_name} ? $options{meta_name} : 'meta';
    my $metaclass = delete $options{metaclass};

    unless ( defined $metaclass ) {
        $metaclass = "Class::MOP::Class";
    } else {
        Class::MOP::load_class($metaclass);
    }

    ($metaclass->isa('Class::MOP::Class'))
        || confess "The metaclass ($metaclass) must be derived from Class::MOP::Class";

    # make sure the custom metaclasses get loaded
    foreach my $key (grep { /_(?:meta)?class$/ } keys %options) {
        unless ( ref( my $class = $options{$key} ) ) {
            Class::MOP::load_class($class)
        }
    }

    my $package = caller();

    # create a meta object so we can install &meta
    my $meta = $metaclass->initialize($package => %options);
    $meta->_add_meta_method($meta_name)
        if defined $meta_name;
}

1;

# ABSTRACT: a pragma for installing and using Class::MOP metaclasses

__END__

=pod

=head1 SYNOPSIS

  package MyClass;

  # use Class::MOP::Class
  use metaclass;

  # ... or use a custom metaclass
  use metaclass 'MyMetaClass';

  # ... or use a custom metaclass
  # and custom attribute and method
  # metaclasses
  use metaclass 'MyMetaClass' => (
      'attribute_metaclass' => 'MyAttributeMetaClass',
      'method_metaclass'    => 'MyMethodMetaClass',
  );

  # ... or just specify custom attribute
  # and method classes, and Class::MOP::Class
  # is the assumed metaclass
  use metaclass (
      'attribute_metaclass' => 'MyAttributeMetaClass',
      'method_metaclass'    => 'MyMethodMetaClass',
  );

  # if we'd rather not install a 'meta' method, we can do this
  use metaclass meta_name => undef;
  # or if we'd like it to have a different name,
  use metaclass meta_name => 'my_meta';

=head1 DESCRIPTION

This is a pragma to make it easier to use a specific metaclass
and a set of custom attribute and method metaclasses. It also
installs a C<meta> method to your class as well, unless C<undef>
is passed to the C<meta_name> option.

=cut
