#define PERL_NO_GET_CONTEXT
#include "mop.h"
#include "moose.h"


typedef struct {
    U16 flags;
    mop_instance_vtbl* vtbl;

    SV* metaclass;
    SV* instance;
    SV* attribute;
} moose_accessor;

/* Moose Accessor meta information */
enum meta_ix_t{
    MA_KEY = 0, /* this must be here (see mop.h) */

    MA_ACCESSOR,
    MA_CLASS,
    MA_INSTANCE,
    MA_ATTRIBUTE,
    MA_TC,
    MA_TC_CODE,

    MA_size
};

#ifndef DEBUGGING
#define MA_of(m, s) (AvARRAY(m)[s])
#else
#define MA_of(m, s) *mop_debug_ma_of(aTHX_ m, s)
static SV**
mop_debug_ma_of(pTHX_ AV* const meta, enum meta_ix_t const ix){
    assert(meta);
    assert(SvTYPE(meta) == SVt_PVAV);
    assert(AvMAX(meta) >= (I32)ix);
    assert(AvARRAY(meta)[ix]);
    return &AvARRAY(meta)[ix];
}
#endif

#define MA_key(m)       MA_of(m, MA_KEY)
#define MA_accessor(m)  MA_of(m, MA_ACCESSOR)
#define MA_class(m)     MA_of(m, MA_CLASS)
#define MA_instance(m)  MA_of(m, MA_INSTANCE)
#define MA_attribute(m) MA_of(m, MA_ATTRIBUTE)
#define MA_tc(m)        MA_of(m, MA_TC)
#define MA_tc_code(m)   MA_of(m, MA_TC_CODE)


enum meta_flags{
    MAf_ATTR_HAS_TC          = 0x0001,
    MAf_ATTR_HAS_DEFAULT     = 0x0002,
    MAf_ATTR_HAS_BUILDER     = 0x0004,
    MAf_ATTR_HAS_INITIALIZER = 0x0008,
    MAf_ATTR_HAS_TRIGGER     = 0x0010,

    MAf_ATTR_IS_LAZY         = 0x0020,
    MAf_ATTR_IS_WEAK_REF     = 0x0040,
    MAf_ATTR_IS_REQUIRED     = 0x0080,

    MAf_ATTR_SHOULD_COERCE   = 0x0100,

    MAf_ATTR_SHOULD_AUTO_DEREF
                             = 0x0200,
    MAf_TC_IS_ARRAYREF       = 0x0400,
    MAf_TC_IS_HASHREF        = 0x0800,

    MAf_OTHER1               = 0x1000,
    MAf_OTHER2               = 0x2000,
    MAf_OTHER3               = 0x4000,
    MAf_OTHER4               = 0x8000,

    MAf_MASK                 = 0xFFFF /* not used */
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

    CV* const xsub  = mop_install_accessor(aTHX_ NULL /* anonymous */, kpv, klen, accessor_impl, instance_vtbl);
    MAGIC* const mg = mop_accessor_get_mg(aTHX_ xsub);
    AV* const meta  = MOP_mg_meta(mg);
    U16 flags = 0;

    assert(instance_vtbl);
    assert(sv_isobject(metaclass));
    assert(sv_isobject(instance));
    assert(sv_isobject(attr));

    /* setup meta information */

    av_extend(meta, MA_size - 1);

    av_store(meta, MA_ACCESSOR,  sv_rvweaken(newSVsv(accessor)));
    av_store(meta, MA_CLASS,     sv_rvweaken(newSVsv(metaclass)));
    av_store(meta, MA_INSTANCE,  sv_rvweaken(newSVsv(instance)));
    av_store(meta, MA_ATTRIBUTE, sv_rvweaken(newSVsv(attr)));

    /* prepare attribute status */
    /* XXX: making it lazy is a good way? */

    if(SvTRUEx(mop_call0_pvs(attr, "has_type_constraint"))){
        SV* tc;
        flags |= MAf_ATTR_HAS_TC;

        ENTER;
        SAVETMPS;

        tc = mop_call0_pvs(attr, "type_constraint");
        av_store(meta, MA_TC, newSVsv(tc));

        if(SvTRUEx(mop_call0_pvs(attr, "should_auto_deref"))){
            flags |= MAf_ATTR_SHOULD_AUTO_DEREF;
            if( SvTRUEx(mop_call1_pvs(tc, "is_a_type_of", newSVpvs_flags("ArrayRef", SVs_TEMP))) ){
                flags |= MAf_TC_IS_ARRAYREF;
            }
            else if( SvTRUEx(mop_call1_pvs(tc, "is_a_type_of", newSVpvs_flags("HashRef", SVs_TEMP))) ){
                flags |= MAf_TC_IS_HASHREF;
            }
            else{
                moose_throw_error(accessor, tc,
                    "Can not auto de-reference the type constraint '%"SVf"'",
                        mop_call0_pvs(tc, "name"));
            }
        }

        if(SvTRUEx(mop_call0_pvs(attr, "should_coerce"))){
            flags |= MAf_ATTR_SHOULD_COERCE;
        }

        FREETMPS;
        LEAVE;
    }

    if(SvTRUEx(mop_call0_pvs(attr, "has_default"))){
        flags |= MAf_ATTR_HAS_DEFAULT;
    }

    if(SvTRUEx(mop_call0_pvs(attr, "has_builder"))){
        flags |= MAf_ATTR_HAS_BUILDER;
    }

    if(SvTRUEx(mop_call0_pvs(attr, "has_initializer"))){
        flags |= MAf_ATTR_HAS_INITIALIZER;
    }

    if(SvTRUEx(mop_call0_pvs(attr, "has_trigger"))){
        flags |= MAf_ATTR_HAS_TRIGGER;
    }

    if(SvTRUEx(mop_call0_pvs(attr, "is_lazy"))){
        flags |= MAf_ATTR_IS_LAZY;
    }

    if(SvTRUEx(mop_call0_pvs(attr, "is_weak_ref"))){
        flags |= MAf_ATTR_IS_WEAK_REF;
    }

    if(SvTRUEx(mop_call0_pvs(attr, "is_required"))){
        flags |= MAf_ATTR_IS_REQUIRED;
    }

    mg->mg_private = flags;

    return xsub;
}

static SV*
moose_apply_tc(pTHX_ AV* const meta, SV* value, U16 const flags){
    SV* const tc      = MA_tc(meta);
    SV* tc_code;

    if(flags & MAf_ATTR_SHOULD_COERCE){
          value = mop_call1_pvs(tc, "coerce", value);
    }

    if(!SvOK(MA_tc_code(meta))){
        tc_code = mop_call0_pvs(tc, "_compiled_type_constraint");
        av_store(meta, MA_TC_CODE, newSVsv(tc_code));
    }
    else{
        tc_code = MA_tc_code(meta);
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
            moose_throw_error(MA_accessor(meta), value,
                "Attribute (%"SVf") does not pass the type constraint because: %"SVf,
                    MA_key(meta),
                    mop_call1_pvs(tc, "get_message", value));
        }
    }

    return value;
}


/* pushes return values, does auto-deref if needed */
static void
moose_push_values(pTHX_ AV* const meta, SV* const value, U16 const flags){
    dSP;

    if(flags & MAf_ATTR_SHOULD_AUTO_DEREF && GIMME_V == G_ARRAY){
        if(!(value && SvOK(value))){
            return;
        }

        if(flags & MAf_TC_IS_ARRAYREF){
            AV* const av = (AV*)SvRV(value);
            I32 len;
            I32 i;

            if(SvTYPE(av) != SVt_PVAV){
                croak("Moose: panic: Not an ARRAY reference for %"SVf,
                        MA_key(meta));
            }

            len = av_len(av) + 1;
            EXTEND(SP, len);
            for(i = 0; i < len; i++){
                SV** const svp = av_fetch(av, i, FALSE);
                PUSHs(svp ? *svp : &PL_sv_undef);
            }
        }
        else if(flags & MAf_TC_IS_HASHREF){
            HV* const hv = (HV*)SvRV(value);
            HE* he;

            if(SvTYPE(hv) != SVt_PVHV){
                croak("Moose: panic: Not a HASH reference for %"SVf,
                        MA_key(meta));
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
    AV* const meta  = MOP_mg_meta(mg);
    U16 const flags = mg->mg_private;
    SV* const key   = MA_key(meta);

    /* check_lazy */
    if( flags & MAf_ATTR_IS_LAZY && !(MOP_mg_vtbl(mg)->has_slot(aTHX_ self, key)) ){
        SV* value = NULL;
        SV* const attr = MA_attribute(meta);
        /* get default value by $attr->default or $attr->builder */
        if(flags & MAf_ATTR_HAS_DEFAULT){
            value = mop_call1_pvs(attr, "default", self);
        }
        else if(flags & MAf_ATTR_HAS_BUILDER){
            SV* const builder = mop_call0_pvs(attr, "builder");
            SV* const method  = mop_call1_pvs(self, "can", builder);
            if(SvOK(method)){
                value = mop_call0(aTHX_ self, method);
            }
            else{
                moose_throw_error(MA_accessor(meta), NULL,
                    "%s does not support builder method '%"SVf"' for attribute '%"SVf"'",
                        HvNAME_get(SvSTASH(SvRV(self))), /* ref($self) */
                        builder,
                        key);
            }
        }

        if(!value){
            value = sv_newmortal();
        }

        /* apply coerce and type constraint */
        if(flags & MAf_ATTR_HAS_TC){
            value = moose_apply_tc(aTHX_ meta, value, flags);
        }

        /* store value to slot, or invoke initializer */
        if(!(flags & MAf_ATTR_HAS_INITIALIZER)){
            (void)MOP_mg_vtbl(mg)->set_slot(aTHX_ self, key, value);
        }
        else{
            /* $attr->set_initial_value($self, $value) */
            dSP;

            PUSHMARK(SP);
            EXTEND(SP, 3);
            PUSHs(MA_attribute(meta));
            PUSHs(self);
            PUSHs(value);
            PUTBACK;

            call_method("set_initial_value", G_VOID | G_DISCARD);
            /* need not SPAGAIN */
        }
    }

    moose_push_values(aTHX_ meta, MOP_mg_vtbl(mg)->get_slot(aTHX_ self, key), flags);
}

static void
moose_attr_set(pTHX_ SV* const self, MAGIC* const mg, SV* value){
    AV* const meta  = MOP_mg_meta(mg);
    U16 const flags = mg->mg_private;
    SV* const key   = MA_key(meta);
    SV* old_value = NULL;

    /*
    if(flags & MAf_ATTR_IS_REQUIRED){
        // XXX: What I should do?
    }
    */

    if(flags & MAf_ATTR_HAS_TC){
        value = moose_apply_tc(aTHX_ meta, value, flags);
    }

    /* get old value for trigger */
    if(flags & MAf_ATTR_HAS_TRIGGER){
        old_value = MOP_mg_vtbl(mg)->get_slot(aTHX_ self, key);
        if(old_value){
            /* XXX: need deep copy for auto-deref? */
            old_value = newSVsv(old_value);
        }
    }

    MOP_mg_vtbl(mg)->set_slot(aTHX_ self, key, value);

    if(flags & MAf_ATTR_IS_WEAK_REF){
        MOP_mg_vtbl(mg)->weaken_slot(aTHX_ self, key);
    }

    if(flags & MAf_ATTR_HAS_TRIGGER){
        SV* const trigger = mop_call0_pvs(MA_attribute(meta), "trigger");
        dSP;

        PUSHMARK(SP);
        EXTEND(SP, 2);
        PUSHs(self);
        PUSHs(value);

        if(old_value){
            PUTBACK;
            moose_push_values(aTHX_ meta, old_value, flags);
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
        moose_throw_error(MA_accessor(MOP_mg_meta(mg)), NULL,
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
        moose_throw_error(MA_accessor(MOP_mg_meta(mg)), newRV_noinc((SV*)args),
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
        moose_throw_error(MA_accessor(MOP_mg_meta(mg)), NULL,
            "expected exactly two arguments");
    }

    SP -= items; /* PPCODE */
    PUTBACK;

    moose_attr_set(aTHX_ self, mg, ST(1));
}
