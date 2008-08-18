#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define SLOT_WEAKEN 0x01

/* FIXME
 * needs to be made into Moose::XS::Meta::Instance and Meta::Slot for the
 * metadata, with a proper destructor. XSANY still points to this struct, but
 * it is shared by all functions of the same type.
 *
 * Instance contains SvSTASH, and SLOT slots[]
 *
 * On recreation of the meta instance we refresh the SLOT value of all the CVs
 * we installed
 *
 * need a good way to handle time between invalidate and regeneration (just
 * check XSANY and call get_meta_instance if null?)
 */


/* FIXME
 * slot access is one of 4 values in flags:
 * 0 == hash
 * 1 == array
 * 3 == fptr (allows access into C structs, etc)
 * 4 == callsv (really a special case of fptr)
 *
 * for fptr case we have a pointer to a vtable for get/set/has/delete, all of which take the same args as set_slot_value
 */

/* FIXME
 * type constraints are already implemented by konobi
 * should be trivial to do coercions for the core types, too
 *
 * TypeConstraint::Class can compare SvSTASH by ptr, and if it's neq *then*
 * call ->isa (should handle vast majority of cases)
 *
 * base parametrized types are also trivial
 *
 * ClassName is get_stathpvn
 */

/* FIXME
 * for a constructor we have SLOT *slots, and iterate that, removing init_arg
 * we can preallocate the structure to the right size (maybe even with the
 * right HEs?), and do various other prehashing hacks to gain speed
 * */

/* FIXME
 * delegations and attribute helpers:
 *
 * typedef struct {
 *      SLOT *slot;
 *      pv *method;
 * } delegation;
 *
 * typedef struct {
 *      SLOT *slot;
 *      I32 *type; // hash, array, whatever + vtable for operation
 * } attributehelper;
 */

typedef struct {
    U32 hash;
    SV *sv;
    U32 flags /* slot type, TC behavior, coerce, weaken, (no default | default, builder + lazy), auto_deref */
    /* FIXME
     * type constraint (pointer or enum union)
     * default / builder ptr (or SV *)
     * initializer
     */
} SLOT;

#define dSLOT SLOT *slot = INT2PTR(SLOT *, XSANY.any_i32)

/* utility functions */

STATIC SLOT *new_slot_from_key (SV *key, U32 flags) {
    SLOT *slot = (SLOT *)malloc(sizeof(SLOT));
    U32 hash;
    STRLEN len;
    char *pv = SvPV(key, len);

    PERL_HASH(hash, pv, len);
    slot->sv = newSVpvn_share(pv, len, hash);
    slot->hash = hash;
    slot->flags = flags;

    return slot;
}

STATIC void weaken(SV *sv) {
#ifdef SvWEAKREF
	sv_rvweaken(sv);
#else
	croak("weak references are not implemented in this release of perl");
#endif
}


/* meta instance protocol */

STATIC SV *get_slot_value(SV *self, SLOT *slot) {
    HE *he;

    assert(self);
    assert(SvROK(self));
    assert(SvTYPE(SvRV(self)) == SVt_PVHV);

    if (he = hv_fetch_ent((HV *)SvRV(self), slot->sv, 0, slot->hash))
        return HeVAL(he);
    else
        return NULL;
}

STATIC void set_slot_value(SV *self, SLOT *slot, SV *value) {
    HE *he;

    assert(self);
    assert(SvROK(self));
    assert(SvTYPE(SvRV(self)) == SVt_PVHV);

    SvREFCNT_inc(value);

    he = hv_store_ent((HV*)SvRV(self), slot->sv, value, slot->hash);
    if (he != NULL) {
        if ( slot->flags & SLOT_WEAKEN )
            weaken(HeVAL(he));
    } else {
        croak("Hash store failed.");
    }
}

STATIC bool has_slot_value(SV *self, SLOT *slot) {
    assert(self);
    assert(SvROK(self));
    assert(SvTYPE(SvRV(self)) == SVt_PVHV);

    return hv_exists_ent((HV *)SvRV(self), slot->sv, slot->hash);
}


/* simple high level api */

STATIC XS(simple_getter);
STATIC XS(simple_getter)
{
#ifdef dVAR
    dVAR;
#endif
    dXSARGS;
    dSLOT;
    SV *value;

    if (items != 1)
        Perl_croak(aTHX_ "Usage: %s(%s)", GvNAME(CvGV(cv)), "self");

    SP -= items;

    value = get_slot_value(ST(0), slot);

    if (value) {
        ST(0) = sv_mortalcopy(value); /* mortalcopy because $_ .= "blah" for $foo->bar */
        XSRETURN(1);
    } else {
        XSRETURN_UNDEF;
    }
}

STATIC XS(simple_setter);
STATIC XS(simple_setter)
{
#ifdef dVAR
    dVAR;
#endif
    dXSARGS;
    dSLOT;

    if (items != 2)
        Perl_croak(aTHX_ "Usage: %s(%s, %s)", GvNAME(CvGV(cv)), "self", "value");

    SP -= items;

    set_slot_value(ST(0), slot, ST(1));

    ST(0) = ST(1); /* return value */
    XSRETURN(1);
}

STATIC XS(simple_accessor);
STATIC XS(simple_accessor)
{
#ifdef dVAR
    dVAR;
#endif
    dXSARGS;
    dSLOT;

    if (items < 1)
        Perl_croak(aTHX_ "Usage: %s(%s, [ %s ])", GvNAME(CvGV(cv)), "self", "value");

    SP -= items;

    if (items > 1) {
        set_slot_value(ST(0), slot, ST(1));
        ST(0) = ST(1); /* return value */
    } else {
        SV *value = get_slot_value(ST(0), slot);
        if ( value ) {
            ST(0) = value;
        } else {
            XSRETURN_UNDEF;
        }
    }

    XSRETURN(1);
}

STATIC XS(predicate);
STATIC XS(predicate)
{
#ifdef dVAR
    dVAR;
#endif
    dXSARGS;
    dSLOT;

    if (items != 1)
        Perl_croak(aTHX_ "Usage: %s(%s)", GvNAME(CvGV(cv)), "self");

    SP -= items;

    if ( has_slot_value(ST(0), slot) )
        XSRETURN_YES;
    else
        XSRETURN_NO;
}

enum xs_body {
    xs_body_simple_getter = 0,
    xs_body_simple_setter,
    xs_body_simple_accessor,
    xs_body_predicate,
    max_xs_body
};

STATIC XSPROTO ((*xs_bodies[])) = {
    simple_getter,
    simple_setter,
    simple_accessor,
    predicate,
};

MODULE = Moose PACKAGE = Moose::XS

CV *
install_sub(name, key)
    INPUT:
        char *name;
        SV *key;
    ALIAS:
        install_simple_getter   = xs_body_simple_getter
        install_simple_setter   = xs_body_simple_setter
        install_simple_accessor = xs_body_simple_accessor
        install_predicate       = xs_body_predicate
    PREINIT:
        CV * cv;
    CODE:
        if ( ix >= max_xs_body )
            croak("Unknown Moose::XS body type");

        cv = newXS(name, xs_bodies[ix], __FILE__);

        if (cv == NULL)
            croak("Oi vey!");

        /* FIXME leaks, fail for anon classes */
        XSANY.any_i32 = PTR2IV(new_slot_from_key(key, 0));

        RETVAL = cv;
    OUTPUT:
        RETVAL


