#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static void
S_reset_amagic (pTHX_ SV *rv, const bool on)
{
    /* It is assumed that you've already turned magic on/off on rv  */

    SV *sva;
    SV *const target = SvRV (rv);

    /* Less 1 for the reference we've already dealt with.  */
    U32 how_many = SvREFCNT (target) - 1;
    MAGIC *mg;

    if (SvMAGICAL (target) && (mg = mg_find (target, PERL_MAGIC_backref))) {
        /* Back references also need to be found, but aren't part of the target's reference count. */
        how_many += 1 + av_len ((AV *)mg->mg_obj);
    }

    if (!how_many) {
        /* There was only 1 reference to this object.  */
        return;
    }

    for (sva = PL_sv_arenaroot; sva; sva = (SV *)SvANY (sva)) {
        register const SV *const svend = &sva[SvREFCNT (sva)];
        register SV *sv;
        for (sv = sva + 1; sv < svend; ++sv) {
            if (SvTYPE (sv) != SVTYPEMASK
             && ((sv->sv_flags & SVf_ROK) == SVf_ROK)
             && SvREFCNT (sv)
             && SvRV (sv) == target
             && sv != rv) {
                if (on) {
                    SvAMAGIC_on (sv);
                }
                else {
                    SvAMAGIC_off (sv);
                }

                if (--how_many == 0) {
                    /* We have found them all. */
                    return;
                }
            }
        }
    }
}

MODULE = Moose::Meta::Role::Application::ToInstance PACKAGE = Moose::Meta::Role::Application::ToInstance

PROTOTYPES: DISABLE

void
_reset_amagic (rv)
        SV *rv
    CODE:
        if (Gv_AMG (SvSTASH (SvRV (rv))) && !SvAMAGIC (rv)) {
            SvAMAGIC_on (rv);
            S_reset_amagic (aTHX_ rv, TRUE);
        }
