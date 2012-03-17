
package Class::MOP::Method::Overload;

use strict;
use warnings;

use Carp 'confess';

use base 'Class::MOP::Method';

sub wrap {
    my $class = shift;
    my (@args) = @_;
    unshift @args, 'body' if @args % 2 == 1;
    my %params = @args;

    confess "operator is required"
        unless exists $params{operator};

    return $class->SUPER::wrap(
        name => "($params{operator}",
        %params,
    );
}

sub _new {
    my $class = shift;
    return Class::MOP::Class->initialize($class)->new_object(@_)
        if $class ne __PACKAGE__;

    my $params = @_ == 1 ? $_[0] : {@_};

    return bless {
        # inherited from Class::MOP::Method
        'body'                 => $params->{body},
        'associated_metaclass' => $params->{associated_metaclass},
        'package_name'         => $params->{package_name},
        'name'                 => $params->{name},
        'original_method'      => $params->{original_method},

        # defined in this class
        'operator'             => $params->{operator},
    } => $class;
}

1;

# ABSTRACT: Method Meta Object for methods which implement overloading

__END__

=pod

=head1 DESCRIPTION

This is a L<Class::MOP::Method> subclass which represents methods that
implement overloading.

=head1 METHODS

=over 4

=item B<< Class::MOP::Method::Overload->wrap($metamethod, %options) >>

This is the constructor. The options accepted are identical to the ones
accepted by L<Class::MOP::Method>, except that it also required an C<operator>
parameter, which should be an operator as defined by the L<overload> pragma.

=item B<< $metamethod->operator >>

This returns the operator that was passed to new.

=back

=cut
