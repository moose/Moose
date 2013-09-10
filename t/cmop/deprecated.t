use strict;
use warnings;

use FindBin;
use File::Spec::Functions;

use Test::More;

use lib catdir($FindBin::Bin, 'lib');

use Class::MOP;

{
    my $warnings;
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    Class::MOP::load_class('BinaryTree');
    like($warnings, qr/^Class::MOP::load_class is deprecated/);
    ok(Class::MOP::does_metaclass_exist('BinaryTree'));
}

{
    my $warnings;
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    ok(Class::MOP::is_class_loaded('BinaryTree'));
    like($warnings, qr/^Class::MOP::is_class_loaded is deprecated/);
}

{
    my $warnings;
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    is(Class::MOP::load_first_existing_class('this::class::probably::doesnt::exist', 'MyMetaClass'), 'MyMetaClass');
    like($warnings, qr/^Class::MOP::load_first_existing_class is deprecated/);
}

done_testing;
