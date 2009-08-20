#define PERL_NO_GET_CONTEXT
#include "mop.h"
#include "moose.h"

/* Moose Meta Instance object */
enum moose_mi_ix_t{
    MOOSE_MI_ACCESSOR = MOP_MI_last,
    MOOSE_MI_CLASS,
    MOOSE_MI_INSTANCE,
    MOOSE_MI_ATTRIBUTE,
    MOOSE_MI_TC,
    MOOSE_MI_TC_CODE,

    MOOSE_MI_last
};

#define MOOSE_mi_slot(m)      MOP_mi_slot(m)
#define MOOSE_mi_accessor(m)  MOP_mi_access(m, MOOSE_MI_ACCESSOR)
#define MOOSE_mi_class(m)     MOP_mi_access(m, MOOSE_MI_CLASS)
#define MOOSE_mi_instance(m)  MOP_mi_access(m, MOOSE_MI_INSTANCE)
#define MOOSE_mi_attribute(m) MOP_mi_access(m, MOOSE_MI_ATTRIBUTE)
#define MOOSE_mi_tc(m)        MOP_mi_access(m, MOOSE_MI_TC)
#define MOOSE_mi_tc_code(m)   MOP_mi_access(m, MOOSE_MI_TC_CODE)

#define MOOSE_mg_accessor(mg) MOOSE_mi_accessor(MOP_mg_mi(mg))

enum moose_mi_flags_t{
    MOOSE_MIf_ATTR_HAS_TC          = 0x0001,
    MOOSE_MIf_ATTR_HAS_DEFAULT     = 0x0002,
    MOOSE_MIf_ATTR_HAS_BUILDER     = 0x0004,
    MOOSE_MIf_ATTR_HAS_INITIALIZER = 0x0008,
    MOOSE_MIf_ATTR_HAS_TRIGGER     = 0x0010,

    MOOSE_MIf_ATTR_IS_LAZY         = 0x0020,
    MOOSE_MIf_ATTR_IS_WEAK_REF     = 0x0040,
    MOOSE_MIf_ATTR_IS_REQUIRED     = 0x0080,

    MOOSE_MIf_ATTR_SHOULD_COERCE   = 0x0100,

    MOOSE_MIf_ATTR_SHOULD_AUTO_DEREF
                                   = 0x0200,
    MOOSE_MIf_TC_IS_ARRAYREF       = 0x0400,
    MOOSE_MIf_TC_IS_HASHREF        = 0x0800,

    MOOSE_MIf_OTHER1               = 0x1000,
    MOOSE_MIf_OTHER2               = 0x2000,
    MOOSE_MIf_OTHER3               = 0x4000,
    MOOSE_MIf_OTHER4               = 0x8000,

    MOOSE_MIf_MOOSE_MISK           = 0xFFFF /* not used */
};


CV*
moose_instantiate_xs_accessor(pTHX_ SV* const accessor, XSPROTO(accessor_impl), const mop_instance_vtbl* const instance_vtbl){
        /* $key = $accessor->associated_attribute->name */
    SV* const metaclass = mop_call0_pvs(accessor,  "associated_metaclass");
    SV* const instance  = mop_call0_pvs(metaclass, "get_meta_instance");
    SV* const attr      = mop_call0_pvs(accessor,  "associated_attribute");

    SV* const key       = mop_call0_pvs(attr, "name");
    STRLEN klen;
    const char* const kpv = SvPV_const(key, klen);

    CV* const xsub        = mop_install_accessor(aTHX_ NULL /* anonymous */, kpv, klen, accessor_impl, instance_vtbl);
    dMOP_mg(xsub);

    AV* const mi = MOP_mg_mi(mg);
    U16 flags    = 0;

    assert(instance_vtbl);
    assert(sv_isobject(metaclass));
    assert(sv_isobject(instance));
    assert(sv_isobject(attr));

    /* setup mi information */

    av_extend(mi, MOOSE_MI_last - 1);

    av_store(mi, MOOSE_MI_ACCESSOR,  sv_rvweaken(newSVsv(accessor)));
    av_store(mi, MOOSE_MI_CLASS,     sv_rvweaken(newSVsv(metaclass)));
    av_store(mi, MOOSE_MI_INSTANCE,  sv_rvweaken(newSVsv(instance)));
    av_store(mi, MOOSE_MI_ATTRIBUTE, sv_rvweaken(newSVsv(attr)));

    /* prepare attribute status */
    /* XXX: making it lazy is a good way? */

    if(SvTRUEx(mop_call0_pvs(attr, "has_type_constraint"))){
        SV* tc;
        flags |= MOOSE_MIf_ATTR_HAS_TC;

        ENTER;
        SAVETMPS;

        tc = mop_call0_pvs(attr, "type_constraint");
        av_store(mi, MOOSE_MI_TC, newSVsv(tc));

        if(SvTRUEx(mop_call0_pvs(attr, "should_auto_deref"))){
            flags |= MOOSE_MIf_ATTR_SHOULD_AUTO_DEREF;
            if( SvTRUEx(mop_call1_pvs(tc, "is_a_type_of", newSVpvs_flags("ArrayRef", SVs_TEMP))) ){
                flags |= MOOSE_MIf_TC_IS_ARRAYREF;
            }
            else if( SvTRUEx(mop_call1_pvs(tc, "is_a_type_of", newSVpvs_flags("HashRef", SVs_TEMP))) ){
                flags |= MOOSE_MIf_TC_IS_HASHREF;
            }
            else{
                moose_throw_error(accessor, tc,
                    "Can not auto de-reference the type constraint '%"SVf"'",
                        mop_call0_pvs(tc, "name"));
            }
        }

        if(SvTRUEx(mop_call0_pvs(attr, "should_coerce"))){
            flags |= MOOSE_MIf_ATTR_SHOULD_COERCE;
        }

        FREETMPS;
        LEAVE;
    }

    if(SvTRUEx(mop_call0_pvs(attr, "has_default"))){
        flags |= MOOSE_MIf_ATTR_HAS_DEFAULT;
    }

    if(SvTRUEx(mop_call0_pvs(attr, "has_builder"))){
        flags |= MOOSE_MIf_ATTR_HAS_BUILDER;
    }

    if(SvTRUEx(mop_call0_pvs(attr, "has_initializer"))){
        flags |= MOOSE_MIf_ATTR_HAS_INITIALIZER;
    }

    if(SvTRUEx(mop_call0_pvs(attr, "has_trigger"))){
        flags |= MOOSE_MIf_ATTR_HAS_TRIGGER;
    }

    if(SvTRUEx(mop_call0_pvs(attr, "is_lazy"))){
        flags |= MOOSE_MIf_ATTR_IS_LAZY;
    }

    if(SvTRUEx(mop_call0_pvs(attr, "is_weak_ref"))){
        flags |= MOOSE_MIf_ATTR_IS_WEAK_REF;
    }

    if(SvTRUEx(mop_call0_pvs(attr, "is_required"))){
        flags |= MOOSE_MIf_ATTR_IS_REQUIRED;
    }

    MOP_mg_flags(mg) = flags;

    return xsub;
}

static SV*
moose_apply_tc(pTHX_ AV* const mi, SV* value, U16 const flags){
    SV* const tc = MOOSE_mi_tc(mi);
    SV* tc_code;

    if(flags & MOOSE_MIf_ATTR_SHOULD_COERCE){
          value = mop_call1_pvs(tc, "coerce", value);
    }

    if(!SvOK(MOOSE_mi_tc_code(mi))){
        tc_code = mop_call0_pvs(tc, "_compiled_type_constraint");
        av_store(mi, MOOSE_MI_TC_CODE, newSVsv(tc_code));
    }
    else{
        tc_code = MOOSE_mi_tc_code(mi);
    }

    /* TODO: implement build-in type constrains in XS */
    {
        bool ok;
        dSP;

        PUSHMARK(SP);
        XPUSHs(value);
        PUTBACK;

        call_sv(tc_code, G_SCALAR);

        SPAGAIN;
        ok = SvTRUEx(POPs);
        PUTBACK;

        if(!ok){
            moose_throw_error(MOOSE_mi_accessor(mi), value,
                "Attribute (%"SVf") does not pass the type constraint because: %"SVf,
                    MOOSE_mi_slot(mi),
                    mop_call1_pvs(tc, "get_message", value));
        }
    }

    return value;
}


/* pushes return values, does auto-deref if needed */
static void
moose_push_values(pTHX_ AV* const mi, SV* const value, U16 const flags){
    dSP;

    if(flags & MOOSE_MIf_ATTR_SHOULD_AUTO_DEREF && GIMME_V == G_ARRAY){
        if(!(value && SvOK(value))){
            return;
        }

        if(flags & MOOSE_MIf_TC_IS_ARRAYREF){
            AV* const av = (AV*)SvRV(value);
            I32 len;
            I32 i;

            if(SvTYPE(av) != SVt_PVAV){
                croak("Moose: panic: Not an ARRAY reference for %"SVf,
                        MOOSE_mi_slot(mi));
            }

            len = av_len(av) + 1;
            EXTEND(SP, len);
            for(i = 0; i < len; i++){
                SV** const svp = av_fetch(av, i, FALSE);
                PUSHs(svp ? *svp : &PL_sv_undef);
            }
        }
        else if(flags & MOOSE_MIf_TC_IS_HASHREF){
            HV* const hv = (HV*)SvRV(value);
            HE* he;

            if(SvTYPE(hv) != SVt_PVHV){
                croak("Moose: panic: Not a HASH reference for %"SVf,
                        MOOSE_mi_slot(mi));
            }

            hv_iterinit(hv);
            while((he = hv_iternext(hv))){
                EXTEND(SP, 2);
                PUSHs(hv_iterkeysv(he));
                PUSHs(hv_iterval(hv, he));
            }
        }
    }
    else{
        XPUSHs(value ? value : &PL_sv_undef);
    }

    PUTBACK;
}

static void
moose_attr_get(pTHX_ SV* const self, MAGIC* const mg){
    AV* const mi    = MOP_mg_mi(mg);
    U16 const flags = MOP_mg_flags(mg);

    /* check_lazy */
    if( flags & MOOSE_MIf_ATTR_IS_LAZY && !MOP_mg_has_slot(mg, self) ){
        SV* value = NULL;
        SV* const attr = MOOSE_mi_attribute(mi);
        /* get default value by $attr->default or $attr->builder */
        if(flags & MOOSE_MIf_ATTR_HAS_DEFAULT){
            value = mop_call1_pvs(attr, "default", self);
        }
        else if(flags & MOOSE_MIf_ATTR_HAS_BUILDER){
            SV* const builder = mop_call0_pvs(attr, "builder");
            SV* const method  = mop_call1_pvs(self, "can", builder);
            if(SvOK(method)){
                value = mop_call0(aTHX_ self, method);
            }
            else{
                moose_throw_error(MOOSE_mi_accessor(mi), NULL,
                    "%s does not support builder method '%"SVf"' for attribute '%"SVf"'",
                        HvNAME_get(SvSTASH(SvRV(self))), /* ref($self) */
                        builder,
                        MOOSE_mi_slot(mi));
            }
        }

        if(!value){
            value = sv_newmortal();
        }

        /* apply coerce and type constraint */
        if(flags & MOOSE_MIf_ATTR_HAS_TC){
            value = moose_apply_tc(aTHX_ mi, value, flags);
        }

        /* store value to slot, or invoke initializer */
        if(!(flags & MOOSE_MIf_ATTR_HAS_INITIALIZER)){
            (void)MOP_mg_set_slot(mg, self, value);
        }
        else{
            /* $attr->set_initial_value($self, $value) */
            dSP;

            PUSHMARK(SP);
            EXTEND(SP, 3);
            PUSHs(MOOSE_mi_attribute(mi));
            PUSHs(self);
            PUSHs(value);
            PUTBACK;

            call_method("set_initial_value", G_VOID | G_DISCARD);
            /* need not SPAGAIN */
        }
    }

    moose_push_values(aTHX_ mi, MOP_mg_get_slot(mg, self), flags);
}

static void
moose_attr_set(pTHX_ SV* const self, MAGIC* const mg, SV* value){
    AV* const mi    = MOP_mg_mi(mg);
    U16 const flags = MOP_mg_flags(mg);
    SV* old_value   = NULL;

    /*
    if(flags & MOOSE_MIf_ATTR_IS_REQUIRED){
        // XXX: What I should do?
    }
    */

    if(flags & MOOSE_MIf_ATTR_HAS_TC){
        value = moose_apply_tc(aTHX_ mi, value, flags);
    }

    /* get old value for trigger */
    if(flags & MOOSE_MIf_ATTR_HAS_TRIGGER){
        old_value = MOP_mg_get_slot(mg, self);
        if(old_value){
            /* XXX: need deep copy for auto-deref? */
            old_value = newSVsv(old_value);
        }
    }

    MOP_mg_set_slot(mg, self, value);

    if(flags & MOOSE_MIf_ATTR_IS_WEAK_REF){
        MOP_mg_weaken_slot(mg, self);
    }

    if(flags & MOOSE_MIf_ATTR_HAS_TRIGGER){
        SV* const trigger = mop_call0_pvs(MOOSE_mi_attribute(mi), "trigger");
        dSP;

        PUSHMARK(SP);
        EXTEND(SP, 2);
        PUSHs(self);
        PUSHs(value);

        if(old_value){
            PUTBACK;
            moose_push_values(aTHX_ mi, old_value, flags);
            SPAGAIN;
        }

        PUTBACK;
        call_sv(trigger, G_VOID | G_DISCARD);
        /* need not SPAGAIN */
    }

    {
        dSP;
        XPUSHs(value);
        PUTBACK;
    }
}

XS(moose_xs_accessor)
{
    dVAR; dXSARGS;
    dMOP_METHOD_COMMON; /* self, mg */

    SP -= items; /* PPCODE */
    PUTBACK;

    if(items == 1){ /* reader */
        moose_attr_get(aTHX_ self, mg);
    }
    else if (items == 2){ /* writer */
        moose_attr_set(aTHX_ self, mg, ST(1));
    }
    else{
        moose_throw_error(MOOSE_mg_accessor(mg), NULL,
            "expected exactly one or two argument");
    }
}


XS(moose_xs_reader)
{
    dVAR; dXSARGS;
    dMOP_METHOD_COMMON; /* self, mg */

    if (items != 1) {
        /* captured args for t/050_metaclasses/018_throw_error.t */
        AV* const args = newAV();
        I32 i;
        for(i = 0; i < items; i++){
            av_push(args, newSVsv(ST(i)));
        }
        moose_throw_error(MOOSE_mg_accessor(mg), newRV_noinc((SV*)args),
            "Cannot assign a value to a read-only accessor '%s'", GvNAME(CvGV(cv)));
    }

    SP -= items; /* PPCODE */
    PUTBACK;

    moose_attr_get(aTHX_ self, mg);
}

XS(moose_xs_writer)
{
    dVAR; dXSARGS;
    dMOP_METHOD_COMMON; /* self, mg */

    if (items != 2) {
        moose_throw_error(MOOSE_mg_accessor(mg), NULL,
            "expected exactly two arguments");
    }

    SP -= items; /* PPCODE */
    PUTBACK;

    moose_attr_set(aTHX_ self, mg, ST(1));
}
