package Moose::Exception::AttributeIsRequired;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Class';

use Moose::Util 'throw_exception';

has 'attribute_name' => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1
);

has 'attribute' => (
    is        => 'ro',
    isa       => 'Class::MOP::Attribute',
    # predicate => 'has_attribute',
    lazy_build => 1
);

has 'params' => (
    is        => 'ro',
    isa       => 'HashRef',
    predicate => 'has_params',
);

sub _build_attribute {
    my $self = shift;
    if( $self->has_attribute_name &&
        $self->is_class_name_set ) {
        $self->class->get_attribute( $self->attribute_name );
    }
}

sub _build_class {
    my $self = shift;
    if( $self->has_attribute ) {
        return $self->attribute->associated_class;
    } elsif( $self->is_class_name_set ) {
        return Class::MOP::class_of( $self->class_name );
    }
};

sub _build_class_name {
    my $self = shift;
    return $self->class->name;
}

sub _has_class_or_class_name {
    my $self = shift;

    if( $self->has_attribute ) {
        return 1;
    } else {
        return $self->is_class_name_set ||
               $self->is_class_set;
    }
}

sub _build_attribute_name {
    my $self = shift;
    if( $self->has_attribute ) {
        return $self->attribute->name;
    } else {
        throw_exception( "NeitherAttributeNorAttributeNameIsGiven" );
    }
}

after "BUILD" => sub {
    my $self = $_[0];

    if( $self->has_attribute_name &&
        $self->has_attribute &&
        ( $self->attribute->name ne $self->attribute_name ) )
    {
        throw_exception( AttributeNamesDoNotMatch => attribute_name => $self->attribute_name,
                                                     attribute      => $self->attribute
                       );
    } elsif( !$self->has_attribute &&
             !$self->is_class_name_set &&
             !$self->is_class_set ) {
        throw_exception( "NeitherClassNorClassNameIsGiven" );
    } elsif( !$self->has_attribute &&
             !$self->has_attribute_name ) {
        throw_exception( "NeitherAttributeNorAttributeNameIsGiven" );
    } elsif( $self->is_class_name_set &&
             $self->has_attribute &&
             ( $self->class_name ne $self->class->name ) ) {
        throw_exception( ClassNamesDoNotMatch => class_name => $self->class_name,
                                                 class      => $self->class,
                       );
    }
};

sub _build_message {
    my $self = shift;
    "Attribute (".$self->attribute_name.") is required";
}

1;
