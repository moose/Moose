package MMHelper;

use strict;
use warnings;

use Config;

sub ccflags_dyn {
    my $is_dev = shift;

    my $ccflags = q<( $Config::Config{ccflags} || '' ) . ' -I.'>;
    if ($is_dev and ($Config{cc} !~ /^cl\b/i)) {
        $ccflags .= q< . ' -Wall -Wdeclaration-after-statement'>;
    }

    return $ccflags;
}

sub ccflags_static {
    my $is_dev = shift;

    return eval(ccflags_dyn($is_dev));
}

sub mm_args {
    my ( @object, %xs );

    for my $xs ( glob "xs/*.xs" ) {
        ( my $c = $xs ) =~ s/\.xs$/.c/i;
        ( my $o = $xs ) =~ s/\.xs$/\$(OBJ_EXT)/i;

        $xs{$xs} = $c;
        push @object, $o;
    }

    for my $c ( glob "*.c" ) {
        ( my $o = $c ) =~ s/\.c$/\$(OBJ_EXT)/i;
        push @object, $o;
    }

    return (
        clean   => { FILES => join( q{ }, @object ) },
        OBJECT => join( q{ }, @object ),
        XS     => \%xs,
    );
}

sub my_package_subs {
    return <<'EOP';
{
package MY;

use Config;

# These two are necessary to keep bmake happy
sub xs_c {
    my $self = shift;
    my $ret = $self->SUPER::xs_c(@_);
    $ret =~ s/\$\*\.xs/\$</g;
    $ret =~ s/\$\*\.c\b/\$@/g;
    return $ret;
}

sub c_o {
    my $self = shift;
    my $ret = $self->SUPER::c_o(@_);
    $ret =~ s/\$\*\.c\b/\$</g;
    $ret =~ s/\$\*\$\(OBJ_EXT\)/\$@/g;
    return $ret;
}

sub const_cccmd {
    my $ret = shift->SUPER::const_cccmd(@_);
    return q{} unless $ret;

    if ($Config{cc} =~ /^cl\b/i) {
        warn 'you are using MSVC... we may not have gotten some options quite right.';
        $ret .= ' /Fo$@';
    }
    else {
        $ret .= ' -o $@';
    }

    return $ret;
}

sub postamble {
    return <<'EOF';
$(OBJECT) : mop.h
EOF
}
}
EOP
}

1;
