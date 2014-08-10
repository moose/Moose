package Class::MOP::Method;
our $VERSION = '2.2006';

use strict;
use warnings;

use Scalar::Util 'weaken', 'reftype', 'blessed';

use parent 'Class::MOP::Object';

# NOTE:
# if poked in the right way,
# they should act like CODE refs.
use overload
    '&{}' => sub { $_[0]->body },
    'bool' => sub { 1 },
    '""' => sub { overload::StrVal($_[0]) },
    fallback => 1;

# construction

sub wrap {
    my ( $class, @args ) = @_;

    unshift @args, 'body' if @args % 2 == 1;

    my %params = @args;
    my $code = $params{body};

    if (blessed($code) && $code->isa(__PACKAGE__)) {
        my $method = $code->clone;
        delete $params{body};
        Class::MOP::class_of($class)->rebless_instance($method, %params);
        return $method;
    }
    elsif (!ref $code || 'CODE' ne reftype($code)) {
        $class->_throw_exception( WrapTakesACodeRefToBless => params => \%params,
                                                                  class  => $class,
                                                                  code   => $code
                                    );
    }

    ($params{package_name} && $params{name})
        || $class->_throw_exception( PackageNameAndNameParamsNotGivenToWrap => params => \%params,
                                                                                   class  => $class,
                                                                                   code   => $code
                                       );

    my $self = $class->_new(\%params);

    weaken($self->{associated_metaclass}) if $self->{associated_metaclass};

    return $self;
}

sub _new {
    my $class = shift;

    return Class::MOP::Class->initialize($class)->new_object(@_)
        if $class ne __PACKAGE__;

    my $params = @_ == 1 ? $_[0] : {@_};

    return bless {
        'body'                 => $params->{body},
        'associated_metaclass' => $params->{associated_metaclass},
        'package_name'         => $params->{package_name},
        'name'                 => $params->{name},
        'original_method'      => $params->{original_method},
    } => $class;
}

## accessors

sub associated_metaclass { shift->{'associated_metaclass'} }

sub attach_to_class {
    my ( $self, $class ) = @_;
    $self->{associated_metaclass} = $class;
    weaken($self->{associated_metaclass});
}

sub detach_from_class {
    my $self = shift;
    delete $self->{associated_metaclass};
}

sub fully_qualified_name {
    my $self = shift;
    $self->package_name . '::' . $self->name;
}

sub original_method { (shift)->{'original_method'} }

sub _set_original_method { $_[0]->{'original_method'} = $_[1] }

# It's possible that this could cause a loop if there is a circular
# reference in here. That shouldn't ever happen in normal
# circumstances, since original method only gets set when clone is
# called. We _could_ check for such a loop, but it'd involve some sort
# of package-lexical variable, and wouldn't be terribly subclassable.
sub original_package_name {
    my $self = shift;

    $self->original_method
        ? $self->original_method->original_package_name
        : $self->package_name;
}

sub original_name {
    my $self = shift;

    $self->original_method
        ? $self->original_method->original_name
        : $self->name;
}

sub original_fully_qualified_name {
    my $self = shift;

    $self->original_method
        ? $self->original_method->original_fully_qualified_name
        : $self->fully_qualified_name;
}

sub execute {
    my $self = shift;
    $self->body->(@_);
}

# We used to go through use Class::MOP::Class->clone_instance to do this, but
# this was awfully slow. This method may be called a number of times when
# classes are loaded (especially during Moose role application), so it is
# worth optimizing. - DR
sub clone {
    my $self = shift;

    my $clone = bless { %{$self}, @_ }, blessed($self);
    weaken($clone->{associated_metaclass}) if $clone->{associated_metaclass};

    $clone->_set_original_method($self);

    return $clone;
}

sub _inline_throw_exception {
    my ( $self, $exception_type, $throw_args ) = @_;
    return
          'die Module::Runtime::use_module("Moose::Exception::'
        . $exception_type
        . '")->new('
        . ( $throw_args || '' ) . ')';
}

1;

# ABSTRACT: Method Meta Object

__END__

=pod

=head1 DESCRIPTION

See the L<Moose::Meta::Method> documentation for API details.

=cut
