package Class::MOP::Method::Constructor;
our $VERSION = '2.2006';

use strict;
use warnings;

use Scalar::Util 'blessed', 'weaken';
use Try::Tiny;

use parent 'Class::MOP::Method::Inlined';

sub new {
    my $class   = shift;
    my %options = @_;

    (blessed $options{metaclass} && $options{metaclass}->isa('Class::MOP::Class'))
        || $class->_throw_exception( MustSupplyAMetaclass => params => \%options,
                                                    class  => $class
                          )
            if $options{is_inline};

    ($options{package_name} && $options{name})
        || $class->_throw_exception( MustSupplyPackageNameAndName => params => \%options,
                                                            class  => $class
                          );

    my $self = $class->_new(\%options);

    # we don't want this creating
    # a cycle in the code, if not
    # needed
    weaken($self->{'associated_metaclass'});

    $self->_initialize_body;

    return $self;
}

sub _new {
    my $class = shift;

    return Class::MOP::Class->initialize($class)->new_object(@_)
        if $class ne __PACKAGE__;

    my $params = @_ == 1 ? $_[0] : {@_};

    return bless {
        # inherited from Class::MOP::Method
        body                 => $params->{body},
        # associated_metaclass => $params->{associated_metaclass}, # overridden
        package_name         => $params->{package_name},
        name                 => $params->{name},
        original_method      => $params->{original_method},

        # inherited from Class::MOP::Generated
        is_inline            => $params->{is_inline} || 0,
        definition_context   => $params->{definition_context},

        # inherited from Class::MOP::Inlined
        _expected_method_class => $params->{_expected_method_class},

        # defined in this subclass
        options              => $params->{options} || {},
        associated_metaclass => $params->{metaclass},
    }, $class;
}

## accessors

sub options              { (shift)->{'options'}              }
sub associated_metaclass { (shift)->{'associated_metaclass'} }

## method

sub _initialize_body {
    my $self        = shift;
    my $method_name = '_generate_constructor_method';

    $method_name .= '_inline' if $self->is_inline;

    $self->{'body'} = $self->$method_name;
}

sub _eval_environment {
    my $self = shift;
    return $self->associated_metaclass->_eval_environment;
}

sub _generate_constructor_method {
    return sub { Class::MOP::Class->initialize(shift)->new_object(@_) }
}

sub _generate_constructor_method_inline {
    my $self = shift;

    my $meta = $self->associated_metaclass;

    my @source = (
        'sub {',
            $meta->_inline_new_object,
        '}',
    );

    warn join("\n", @source) if $self->options->{debug};

    my $code = try {
        $self->_compile_code(\@source);
    }
    catch {
        my $source = join("\n", @source);
        $self->_throw_exception( CouldNotEvalConstructor => constructor_method => $self,
                                                    source             => $source,
                                                    error              => $_
                       );
    };

    return $code;
}

1;

# ABSTRACT: Method Meta Object for constructors

__END__

=pod

=head1 DESCRIPTION

See the L<Moose::Meta::Method::Constructor> documentation for API details.

=cut
