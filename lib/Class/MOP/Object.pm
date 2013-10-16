
package Class::MOP::Object;

use strict;
use warnings;

use Scalar::Util 'blessed';

# introspection

sub meta {
    require Class::MOP::Class;
    Class::MOP::Class->initialize(blessed($_[0]) || $_[0]);
}

sub _new {
    Class::MOP::class_of(shift)->new_object(@_);
}

# RANT:
# Cmon, how many times have you written
# the following code while debugging:
#
#  use Data::Dumper;
#  warn Dumper $obj;
#
# It can get seriously annoying, so why
# not just do this ...
sub dump {
    my $self = shift;
    require Data::Dumper;
    local $Data::Dumper::Maxdepth = shift || 1;
    Data::Dumper::Dumper $self;
}

sub _real_ref_name {
    my $self = shift;
    return blessed($self);
}

sub _is_compatible_with {
    my $self = shift;
    my ($other_name) = @_;

    return $self->isa($other_name);
}

sub _can_be_made_compatible_with {
    my $self = shift;
    return !$self->_is_compatible_with(@_)
        && defined($self->_get_compatible_metaclass(@_));
}

sub _make_compatible_with {
    my $self = shift;
    my ($other_name) = @_;

    my $new_metaclass = $self->_get_compatible_metaclass($other_name);

    unless ( defined $new_metaclass ) {
        require Moose::Util;
        Moose::Util::throw_exception( CannotMakeMetaclassCompatible => superclass_name => $other_name,
                                                                       class           => $self,
                                    );
    }

    # can't use rebless_instance here, because it might not be an actual
    # subclass in the case of, e.g. moose role reconciliation
    $new_metaclass->meta->_force_rebless_instance($self)
        if blessed($self) ne $new_metaclass;

    return $self;
}

sub _get_compatible_metaclass {
    my $self = shift;
    my ($other_name) = @_;

    return $self->_get_compatible_metaclass_by_subclassing($other_name);
}

sub _get_compatible_metaclass_by_subclassing {
    my $self = shift;
    my ($other_name) = @_;
    my $meta_name = blessed($self) ? $self->_real_ref_name : $self;

    if ($meta_name->isa($other_name)) {
        return $meta_name;
    }
    elsif ($other_name->isa($meta_name)) {
        return $other_name;
    }

    return;
}

1;

# ABSTRACT: Base class for metaclasses

__END__

=pod

=head1 DESCRIPTION

This class is a very minimal base class for metaclasses.

=head1 METHODS

This class provides a few methods which are useful in all metaclasses.

=over 4

=item B<< Class::MOP::???->meta >>

This returns a L<Class::MOP::Class> object.

=item B<< $metaobject->dump($max_depth) >>

This method uses L<Data::Dumper> to dump the object. You can pass an
optional maximum depth, which will set C<$Data::Dumper::Maxdepth>. The
default maximum depth is 1.

=back

=cut
