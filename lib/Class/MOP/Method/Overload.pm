
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

    confess "op is required"
        unless exists $params{op};

    return $class->SUPER::wrap(
        name => "($params{op}",
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
        'op'                   => $params->{op},
    } => $class;
}

1;
