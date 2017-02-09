#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_SvRX
#include "ppport.h"

#include "mop.h"

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

XS_EXTERNAL(boot_Class__MOP);
XS_EXTERNAL(boot_Class__MOP__Mixin__HasAttributes);
XS_EXTERNAL(boot_Class__MOP__Mixin__HasMethods);
XS_EXTERNAL(boot_Class__MOP__Package);
XS_EXTERNAL(boot_Class__MOP__Mixin__AttributeCore);
XS_EXTERNAL(boot_Class__MOP__Method);
XS_EXTERNAL(boot_Class__MOP__Method__Inlined);
XS_EXTERNAL(boot_Class__MOP__Method__Generated);
XS_EXTERNAL(boot_Class__MOP__Class);
XS_EXTERNAL(boot_Class__MOP__Attribute);
XS_EXTERNAL(boot_Class__MOP__Instance);
XS_EXTERNAL(boot_Moose__Meta__Role__Application__ToInstance);

MODULE = Moose  PACKAGE = Moose::Exporter

PROTOTYPES: DISABLE

BOOT:
    mop_prehash_keys();

    MOP_CALL_BOOT (boot_Class__MOP);
    MOP_CALL_BOOT (boot_Class__MOP__Mixin__HasAttributes);
    MOP_CALL_BOOT (boot_Class__MOP__Mixin__HasMethods);
    MOP_CALL_BOOT (boot_Class__MOP__Package);
    MOP_CALL_BOOT (boot_Class__MOP__Mixin__AttributeCore);
    MOP_CALL_BOOT (boot_Class__MOP__Method);
    MOP_CALL_BOOT (boot_Class__MOP__Method__Inlined);
    MOP_CALL_BOOT (boot_Class__MOP__Method__Generated);
    MOP_CALL_BOOT (boot_Class__MOP__Class);
    MOP_CALL_BOOT (boot_Class__MOP__Attribute);
    MOP_CALL_BOOT (boot_Class__MOP__Instance);
    MOP_CALL_BOOT (boot_Moose__Meta__Role__Application__ToInstance);

void
_flag_as_reexport (SV *sv)
    CODE:
        sv_magicext(SvRV(sv), NULL, PERL_MAGIC_ext, &export_flag_vtbl, NULL, 0);

bool
_export_is_flagged (SV *sv)
    CODE:
        RETVAL = export_flag_is_set(aTHX_ sv);
    OUTPUT:
        RETVAL

MODULE = Moose  PACKAGE = Moose::Util::TypeConstraints::Builtins

bool
_RegexpRef (SV *sv=NULL)
    INIT:
        if (!items) {
            sv = DEFSV;
        }
    CODE:
        RETVAL = SvRXOK(sv);
    OUTPUT:
        RETVAL
