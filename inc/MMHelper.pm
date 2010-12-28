package MMHelper;

use strict;
use warnings;

use Config;
use Cwd qw( abs_path );
use File::Basename qw( dirname );

sub mm_args {
    my $is_dev = shift;

    my $ccflags = ( $Config::Config{ccflags} || '' ) . ' -I.';
    $ccflags .= ' -Wall -Wdeclaration-after-statement'
        if $is_dev;

    my %mm = ( CCFLAGS => $ccflags );

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
        CCFLAGS => $ccflags,
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

sub const_cccmd {
    my $ret = shift->SUPER::const_cccmd(@_);
    return q{} unless $ret;

    if ($Config{cc} =~ /^cl\b/i) {
        warn 'you are using MSVC... my condolences.';
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
