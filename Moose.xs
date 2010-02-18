#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#ifndef MGf_COPY
# define MGf_COPY 0
#endif

#ifndef MGf_DUP
# define MGf_DUP 0
#endif

#ifndef MGf_LOCAL
# define MGf_LOCAL 0
#endif

STATIC int unset_export_flag (pTHX_ SV *sv, MAGIC *mg);

STATIC MGVTBL export_flag_vtbl = {
    NULL, /* get */
    unset_export_flag, /* set */
    NULL, /* len */
    NULL, /* clear */
    NULL, /* free */
#if MGf_COPY
    NULL, /* copy */
#endif
#if MGf_DUP
    NULL, /* dup */
#endif
#if MGf_LOCAL
    NULL, /* local */
#endif
};

STATIC bool
export_flag_is_set (pTHX_ SV *sv)
{
    MAGIC *mg, *moremagic;

    if (SvTYPE(SvRV(sv)) != SVt_PVGV) {
        return 0;
    }

    for (mg = SvMAGIC(SvRV(sv)); mg; mg = moremagic) {
        moremagic = mg->mg_moremagic;

        if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == &export_flag_vtbl) {
            break;
        }
    }

    return !!mg;
}

STATIC int
unset_export_flag (pTHX_ SV *sv, MAGIC *mymg)
{
    MAGIC *mg, *prevmagic = NULL, *moremagic = NULL;

    for (mg = SvMAGIC(sv); mg; prevmagic = mg, mg = moremagic) {
        moremagic = mg->mg_moremagic;

        if (mg == mymg) {
            break;
        }
    }

    if (!mg) {
        return 0;
    }

    if (prevmagic) {
        prevmagic->mg_moremagic = moremagic;
    }
    else {
        SvMAGIC_set(sv, moremagic);
    }

    mg->mg_moremagic = NULL;

    Safefree (mg);

    return 0;
}

MODULE = Moose  PACKAGE = Moose::Exporter

void
_flag_as_reexport (SV *sv)
    PROTOTYPE: \*
    CODE:
        sv_magicext(SvRV(sv), NULL, PERL_MAGIC_ext, &export_flag_vtbl, NULL, 0);

bool
_export_is_flagged (SV *sv)
    PROTOTYPE: \*
    CODE:
        RETVAL = export_flag_is_set(aTHX_ sv);
    OUTPUT:
        RETVAL
