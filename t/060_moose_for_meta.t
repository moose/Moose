#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 16;
use Test::Exception;

BEGIN {
    use_ok('Moose');           
}

{
    package My::Meta::Class;
    use strict;
    use warnings;
    use Moose;
    
    extends 'Moose::Meta::Class';
}

my $anon = My::Meta::Class->create_anon_class();
isa_ok($anon, 'My::Meta::Class');
isa_ok($anon, 'Moose::Meta::Class');
isa_ok($anon, 'Class::MOP::Class');

{
    package My::Meta::Attribute::DefaultReadOnly;
    use strict;
    use warnings;
    use Moose;
    
    extends 'Moose::Meta::Attribute';
    
    around 'new' => sub {
        my $next = shift;
        my $self = shift;
        my $name = shift;
        $next->($self, $name, (is => 'ro'), @_);
    };    
}

{
    my $attr = My::Meta::Attribute::DefaultReadOnly->new('foo');
    isa_ok($attr, 'My::Meta::Attribute::DefaultReadOnly');
    isa_ok($attr, 'Moose::Meta::Attribute');
    isa_ok($attr, 'Class::MOP::Attribute');

    ok($attr->has_reader, '... the attribute has a reader (as expected)');
    ok(!$attr->has_writer, '... the attribute does not have a writer (as expected)');
    ok(!$attr->has_accessor, '... the attribute does not have an accessor (as expected)');
}

{
    my $attr = My::Meta::Attribute::DefaultReadOnly->new('foo', (is => 'rw'));
    isa_ok($attr, 'My::Meta::Attribute::DefaultReadOnly');
    isa_ok($attr, 'Moose::Meta::Attribute');
    isa_ok($attr, 'Class::MOP::Attribute');

    ok(!$attr->has_reader, '... the attribute does not have a reader (as expected)');
    ok(!$attr->has_writer, '... the attribute does not have a writer (as expected)');
    ok($attr->has_accessor, '... the attribute does have an accessor (as expected)');
}

