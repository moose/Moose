#include "mop.h"

static bool
find_method (const char *key, STRLEN keylen, SV *val, void *ud)
{
    bool *found_method = (bool *)ud;
    PERL_UNUSED_ARG(key);
    PERL_UNUSED_ARG(keylen);
    PERL_UNUSED_ARG(val);
    *found_method = TRUE;
    return FALSE;
}

static bool
check_version (SV *klass, SV *required_version)
{
    bool ret = 0;

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(klass);
    PUSHs(required_version);
    PUTBACK;

    call_method("VERSION", G_DISCARD|G_VOID|G_EVAL);

    SPAGAIN;

    if (!SvTRUE(ERRSV)) {
        ret = 1;
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    return ret;
}

MODULE = Class::MOP   PACKAGE = Class::MOP

PROTOTYPES: DISABLE

# use prototype here to be compatible with get_code_info from Sub::Identify
void
get_code_info(coderef)
    SV *coderef
    PROTOTYPE: $
    PREINIT:
        char *pkg  = NULL;
        char *name = NULL;
    PPCODE:
        SvGETMAGIC(coderef);
        if (mop_get_code_info(coderef, &pkg, &name)) {
            EXTEND(SP, 2);
            mPUSHs(newSVpv(pkg, 0));
            mPUSHs(newSVpv(name, 0));
        }

void
is_class_loaded(klass, options=NULL)
    SV *klass
    HV *options
    PREINIT:
        HV *stash;
        bool found_method = FALSE;
    PPCODE:
        SvGETMAGIC(klass);
        if (!(SvPOKp(klass) && SvCUR(klass))) { /* XXX: SvPOK does not work with magical scalars */
            XSRETURN_NO;
        }

        stash = gv_stashsv(klass, 0);
        if (!stash) {
            XSRETURN_NO;
        }

        if (options && hv_exists_ent(options, KEY_FOR(_version), HASH_FOR(_version))) {
            HE *required_version = hv_fetch_ent(options, KEY_FOR(_version), 0, HASH_FOR(_version));
            if (check_version (klass, HeVAL(required_version))) {
                XSRETURN_YES;
            }

            XSRETURN_NO;
        }

        if (hv_exists_ent (stash, KEY_FOR(VERSION), HASH_FOR(VERSION))) {
            HE *version = hv_fetch_ent(stash, KEY_FOR(VERSION), 0, HASH_FOR(VERSION));
            SV *version_sv;
            if (version && HeVAL(version) && (version_sv = GvSV(HeVAL(version)))) {
                if (SvROK(version_sv)) {
                    SV *version_sv_ref = SvRV(version_sv);

                    if (SvOK(version_sv_ref)) {
                        XSRETURN_YES;
                    }
                }
                else if (SvOK(version_sv)) {
                    XSRETURN_YES;
                }
            }
        }

        if (hv_exists_ent (stash, KEY_FOR(ISA), HASH_FOR(ISA))) {
            HE *isa = hv_fetch_ent(stash, KEY_FOR(ISA), 0, HASH_FOR(ISA));
            if (isa && HeVAL(isa) && GvAV(HeVAL(isa)) && av_len(GvAV(HeVAL(isa))) != -1) {
                XSRETURN_YES;
            }
        }

        mop_get_package_symbols(stash, TYPE_FILTER_CODE, find_method, &found_method);
        if (found_method) {
            XSRETURN_YES;
        }

        XSRETURN_NO;
