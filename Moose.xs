#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_grok_number
#define NEED_grok_numeric_radix
#define NEED_newRV_noinc
#define NEED_newSVpvn_share
#define NEED_sv_2pv_flags
#include "ppport.h"

#ifndef XSPROTO
#define XSPROTO(name) void name(pTHX_ CV* cv)
#endif

#ifndef gv_stashpvs
#define gv_stashpvs(x, y) Perl_gv_stashpvn(aTHX_ STR_WITH_LEN(x), y)
#endif

/* FIXME
 * delegations and attribute helpers:
 *
 * typedef struct {
 *      ATTR *attr;
 *      pv *method;
 * } delegation;
 *
 * typedef struct {
 *      ATTR *attr;
 *      I32 *type; // hash, array, whatever + vtable for operation
 * } attributehelper;
 */







/* These two functions attach magic with no behavior to an SV.
 *
 * The stashed value is reference counted, and is destroyed when it's parent
 * object is destroyed.
 *
 * This is used to keep a reference the the meta attribute from a generated
 * method, and to cache the C struct based wrapper attached to the meta
 * instance.
 */

STATIC MGVTBL null_mg_vtbl = {
    NULL, /* get */
    NULL, /* set */
    NULL, /* len */
    NULL, /* clear */
    NULL, /* free */
#if MGf_COPY
    NULL, /* copy */
#endif /* MGf_COPY */
#if MGf_DUP
    NULL, /* dup */
#endif /* MGf_DUP */
#if MGf_LOCAL
    NULL, /* local */
#endif /* MGf_LOCAL */
};

STATIC MAGIC *stash_in_mg (pTHX_ SV *sv, SV *obj) {
    MAGIC *mg = sv_magicext(sv, obj, PERL_MAGIC_ext, &null_mg_vtbl, NULL, 0 );
    mg->mg_flags |= MGf_REFCOUNTED;

    return mg;
}

STATIC SV *get_stashed_in_mg(pTHX_ SV *sv) {
    MAGIC *mg;

    if (SvTYPE(sv) >= SVt_PVMG) {
        for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic) {
            if ((mg->mg_type == PERL_MAGIC_ext) && (mg->mg_virtual == &null_mg_vtbl))
                break;
        }
        if (mg)
            return mg->mg_obj;
    }

    return NULL;
}









/* The folloing data structures deal with type constraints */

/* this is an enum of the various kinds of constraint checking an attribute can
 * have.
 *
 * tc_cv is the fallback behavior (simply applying the
 * ->_compiled_type_constraint to the value, but other more optimal checks are
 *  implemented too. */

typedef enum {
    tc_none = 0, /* no type checking */
    tc_type, /* a builtin type to be checked by check_sv_type */
    tc_stash, /* a stash for a class, implements TypeConstraint::Class by comparing SvSTASH and then invoking C<isa> if necessary */
    tc_cv, /* applies a code reference to the value and checks for truth */
    tc_fptr, /* apply a C function pointer */
    tc_enum /* TODO check that the value is in an allowed set of values (strings) */
} tc_kind;

/* this is a enum of builtin type check. They are handled in a switch statement
 * in check_sv_type */
typedef enum {
    Any, /* or item, or bool */
    Undef,
    Defined,
    Str, /* or value */
    Num,
    Int,
    GlobRef, /* SVt_PVGV */
    ArrayRef, /* SVt_PVAV */
    HashRef, /* SVt_PVHV */
    CodeRef, /* SVt_PVCV */
    Ref,
    ScalarRef,
    FileHandle, /* TODO */
    RegexpRef,
    Object,
    Role, /* TODO */
    ClassName
} TC;

/* auxillary pointer/int union used for constraint checking */
typedef union {
    TC type; /* the builtin type number for tc_type */
    SV *sv; /* the cv for tc_cv, or the stash for tc_stash */
    OP *op; /* TODO not used */
    bool (*fptr)(pTHX_ SV *type_constraint, SV *sv); /* the function pointer for tc_fptr  FIXME aux data? */
} TC_CHECK;






/* The folloing data structures deal with type default value generation */

/* This is an enum for the various types of default value behaviors an
 * attribute can have */

typedef enum {
    default_none = 0, /* no default value */
    default_normal, /* code reference or scalar */
    default_builder, /* builder method */
    default_type /* TODO enumerated type optimization (will call newHV, newAV etc to avoid calling a code ref for these simple cases) */
} default_kind;

typedef union {
    SV *sv; /* The default value, or a code ref to generate one. If builder then this sv is applied as a method (stringified) */
    U32 type; /* TODO for default_type, should probably be one of SVt_PVAV/SVt_PVHV */
} DEFAULT;






/* the ATTR struct contains all the meta data for a Moose::Meta::Attribute for
 * a given meta instance
 *
 * flags determines the various behaviors
 *
 * This supports only one slot per attribute in the current implementation, but
 * slot_sv could contain an array
 *
 * A list of XSUBs that rely on this attr struct are cross indexed in the cvs
 * array, so that when the meta instance is destroyed the XSANY field will be
 * cleared. This is done in delete_mi
 * */

typedef struct {
    /* pointer to the MI this attribute is a part of the meta instance struct */
    struct mi *mi;

    U32 flags; /* slot type, TC behavior, coerce, weaken, (no default | default, builder + lazy), auto_deref */

    /* slot access fields */
    SV *slot_sv; /* value of the slot (currently always slot name) */
    U32 slot_u32; /* for optimized access (precomputed hash, possibly something else) */

    SV *init_arg_sv;
    U32 init_arg_u32;

    DEFAULT def; /* cv, value or other, depending on flags */

    TC_CHECK tc_check; /* see TC_CHECK*/
    SV *type_constraint; /* Moose::Meta::TypeConstraint object */

    CV *initializer; /* TODO */
    CV *trigger; /* TODO */

    SV *meta_attr; /* the Moose::Meta::Attribute */
    AV *cvs; /* an array of CVs which use this attr, see delete_mi */
} ATTR;

/* the flags integer is mapped as follows
 * instance     misc  reading  writing
 * 00000000 00000000 00000000 00000000
 *                                     writing
 *                             ^       trigger
 *                              ^      weak
 *                               ^     tc.sv is refcounted
 *                                 ^^^ tc_kind
 *                                ^    coerce
 *
 *                                     reading
 *                        ^^^          default_kind
 *                       ^             lazy
 *                      ^              def.sv is refcounted
 *
 *                                     misc
 *                 ^                   attr is required TODO
 *
 *                                     flags having to do with the instance layout (TODO, only hash supported for now)
 * ^^^^^^^                             if 0 then nothing special (just hash)? FIXME TBD
 */

#define ATTR_INSTANCE_MASK 0xff000000
#define ATTR_READING_MASK  0x0000ff00
#define ATTR_WRITING_MASK  0x000000ff

#define ATTR_MASK_TYPE 0x7

#define ATTR_MASK_DEFAULT 0x700
#define ATTR_SHIFT_DEFAULT 8

#define ATTR_LAZY 0x800
#define ATTR_DEFREFCNT 0x1000

#define ATTR_COERCE 0x8
#define ATTR_TCREFCNT 0x10
#define ATTR_WEAK 0x20
#define ATTR_TRIGGER 0x40

#define ATTR_ISWEAK(attr) ( attr->flags & ATTR_WEAK )
#define ATTR_ISLAZY(attr) ( attr->flags & ATTR_LAZY )
#define ATTR_ISCOERCE(attr) ( attr->flags & ATTR_COERCE )

#define ATTR_TYPE(f) ( attr->flags & 0x7 )
#define ATTR_DEFAULT(f) ( ( attr->flags & ATTR_MASK_DEFAULT ) >> ATTR_SHIFT_DEFAULT )

#define ATTR_DUMB_READER(attr) !ATTR_IS_LAZY(attr)
#define ATTR_DUMB_WRITER(attr) ( ( attr->flags & ATTR_WRITING_MASK ) == 0 )
#define ATTR_DUMB_INSTANCE(attr) ( ( attr->flags & ATTR_INSTANCE_MASK ) == 0 )



/* This unused (TODO) vtable will implement the meta instance protocol in terms
 * of function pointers to allow the XS accessors to be used with custom meta
 * instances in the future.
 *
 * We'll need to define a default instance of this vtable that uses call_sv,
 * too. */

/* FIXME define a vtable that does call_sv for fallback meta instance protocol */
typedef struct {
    SV * (*get)(pTHX_ SV *self, ATTR *attr);
    void (*set)(pTHX_ SV *self, ATTR *attr, SV *value);
    bool * (*has)(pTHX_ SV *self, ATTR *attr);
    SV * (*delete)(pTHX_ SV *self, ATTR *attr);
} instance_vtbl;

/* TODO this table describes the instance layout of the object. Not yet
 * implemented */
typedef enum {
    hash = 0,

    /* these are not yet implemented */
    array,
    fptr,
    cv,
    judy
} instance_types;


/* this struct models the meta instance *and* meta attributes simultaneously.
 * It is a cache of the meta attribute behaviors for a given class or subclass
 * and can be parametrized on that level
 *
 *
 * An object pointing to this structure is kept in a refcounted magic inside
 * the meta instance it corresponds to. On C<invalidate_meta_instance> the meta
 * instance is destroyed, causing the proxy object to be destroyed, deleting
 * this structure, clearing the XSANY of all dependent attribute methods.
 *
 * The next invocation of an attribute method will eventually call get_attr,
 * which will call C<get_meta_instance> on the metaclass (recreating it in the
 * Class::MOP level), and cache a new MI struct inside it. Subsequent
 * invocations of get_attr will then search the MI for an ATTR matching the
 * meta_attribute of the attribute method */
typedef struct mi {
    HV *stash;

    /* slot access method */
    instance_types type; /* TODO only hashes supported currently */
    instance_vtbl *vtbl; /* TODO */

    /* attr descriptors */
    I32 num_attrs;
    ATTR *attrs;
} MI;








/* these functions implement type constraint checking */

/* checks that the SV is a scalar ref */
STATIC bool check_is_scalar_ref(SV *sv) {
    if( SvROK(sv) ) {
        switch (SvTYPE(SvRV(sv))) {
            case SVt_IV:
            case SVt_NV:
            case SVt_PV:
            case SVt_NULL:
                return 1;
                break;
            default:
                return 0;
        }
    }
    return 0;
}

/* checks that the SV is a ref to a certain SvTYPE, where type is in the table
 * above */
STATIC bool check_reftype(TC type, SV *sv) {
    int svt;

    if ( !SvROK(sv) )
        return 0;

    switch (type) {
        case GlobRef:
            svt = SVt_PVGV;
            break;
        case ArrayRef:
            svt = SVt_PVAV;
            break;
        case HashRef:
            svt = SVt_PVHV;
            break;
        case CodeRef:
            svt = SVt_PVCV;
            break;
        default:
            croak("not a reftype %d\n", type);
    }

    return SvTYPE(SvRV(sv)) == svt;
}

/* checks whether an SV is of a certain class
 * SvSTASH is first compared by pointer for efficiency */
STATIC bool check_sv_class(pTHX_ HV *stash, SV *sv) {
    dSP;
    bool ret;
    SV *rv;

    if (!sv)
        return 0;
    SvGETMAGIC(sv);
    if (!SvROK(sv))
        return 0;
    rv = (SV*)SvRV(sv);
    if (!SvOBJECT(rv))
        return 0;
    if (SvSTASH(rv) == stash)
        return 1;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv);
    XPUSHs(sv_2mortal(newSVpv(HvNAME_get(stash), 0)));
    PUTBACK;

    call_method("isa", G_SCALAR);

    SPAGAIN;
    ret = SvTRUE(TOPs);

    FREETMPS;
    LEAVE;

    return ret;
}

/* checks whether SV of of a known simple type. Most of the non parametrized
 * Moose core types are implemented here */
STATIC bool check_sv_type (TC type, SV *sv) {
    if (!sv)
        return 0;

    SvGETMAGIC(sv);

    switch (type) {
        case Any:
            return 1;
            break;
        case Undef:
            return !SvOK(sv);
            break;
        case Defined:
            return SvOK(sv);
            break;
        case Str:
            return (SvOK(sv) && !SvROK(sv));
        case Num:
#if (PERL_VERSION < 8) || (PERL_VERSION == 8 && PERL_SUBVERSION <5)
            if (!SvPOK(sv) && !SvPOKp(sv))
                return SvFLAGS(sv) & (SVf_NOK|SVp_NOK|SVf_IOK|SVp_IOK);
            else
#endif
                return looks_like_number(sv);
            break;
        case Int:
            if ( SvIOK(sv) ) {
                return 1;
            } else if ( SvPOK(sv) ) {
                STRLEN len;
                char *pv = SvPV(sv, len);
                int flags = grok_number(pv, len, NULL);
                return ( flags && !(flags & IS_NUMBER_NOT_INT) );
            }
            return 0;
            break;
        case Ref:
            return SvROK(sv);
            break;
        case ScalarRef:
            return check_is_scalar_ref(sv);
            break;
        case ArrayRef:
        case HashRef:
        case CodeRef:
        case GlobRef:
            return check_reftype(type, sv);
            break;
        case RegexpRef:
        case Object:
            /* not using sv_isobject to avoid repeated get magic */
            if ( SvROK(sv) ) {
                SV *rv = SvRV(sv);
                if ( SvOBJECT(rv) ) {
                    char *name = HvNAME_get(SvSTASH(SvRV(sv)));
                    bool is_regexp = strEQ("Regexp", name);
                    return ( (type == RegexpRef) ^ !is_regexp );
                }
            }
            return 0;
            break;
        case ClassName:
            if ( SvOK(sv) && !SvROK(sv) ) {
                STRLEN len;
                char *pv;
                pv = SvPV(sv, len);
                return ( gv_stashpvn(pv, len, 0) != NULL );
            }
            return 0;
            break;
        case FileHandle:
            croak("todo");
            break;
        default:
            croak("todo");
    }

    return 0;
}

/* invoke a CV on an SV and return SvTRUE of the result */
STATIC bool check_sv_cv (pTHX_ SV *cv, SV *sv) {
    bool ret;
    dSP;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv);
    PUTBACK;

    call_sv(cv, G_SCALAR);

    SPAGAIN;
    ret = SvTRUE(POPs);

    PUTBACK;
    FREETMPS;
    LEAVE;

    return ret;
}

/* checks the type constraint for an SV based on the type constraint kind */
STATIC bool check_type_constraint(pTHX_ tc_kind kind, TC_CHECK tc_check, SV *type_constraint, SV *sv) {
    switch (kind) {
        case tc_none:
            return 1;
            break;
        case tc_type:
            return check_sv_type(tc_check.type, sv);
            break;
        case tc_stash:
            return check_sv_class(aTHX_ (HV *)tc_check.sv, sv);
            break;
        case tc_fptr:
            return tc_check.fptr(aTHX_ type_constraint, sv);
            break;
        case tc_cv:
            return check_sv_cv(aTHX_ tc_check.sv, sv);
            break;
        case tc_enum:
            croak("todo\n");
            break;
    }

    croak("todo");
    return 0;
}


/* end of type constraint checking functions */









/* Initialize the ATTR structure using positional arguments from Perl space. */

STATIC void init_attr (MI *mi, ATTR *attr, AV *desc) {
    U32 flags = 0;
    U32 slot_hash, init_arg_hash;
    STRLEN slot_len, init_arg_len;
    char *slot_pv, *init_arg_pv;
    I32 ix = av_len(desc);
    SV **params = AvARRAY(desc);
    SV *tc;
    SV *slot_sv;
    SV *init_arg_sv;

    attr->mi = mi;

    if ( ix != 13 )
        croak("wrong number of args (%d != 14)", (int)ix + 1);

    for ( ; ix >= 0; ix-- ) {
        if ( !params[ix] || params[ix] == &PL_sv_undef )
            croak("bad params");
    }



    /* handle attribute slot array */

    if ( !SvROK(params[1]) || SvTYPE(SvRV(params[1])) != SVt_PVAV )
        croak("slots is not an array");

    if ( av_len((AV *)SvRV(params[1])) != 0 )
        croak("Only unary slots are supported at the moment");

    /* calculate a hash from the slot */
    /* FIXME arrays etc should also be supported */
    slot_sv = *av_fetch((AV *)SvRV(params[1]), 0, 0);
    slot_pv = SvPV(slot_sv, slot_len);
    PERL_HASH(slot_hash, slot_pv, slot_len);


    init_arg_sv = params[13];
    init_arg_pv = SvPV(init_arg_sv, init_arg_len);
    PERL_HASH(init_arg_hash, init_arg_pv, init_arg_len);


    /* FIXME better organize these, positionals suck */
    if ( SvTRUE(params[2]) )
        flags |= ATTR_WEAK;

    if ( SvTRUE(params[3]) )
        flags |= ATTR_COERCE;

    if ( SvTRUE(params[4]) )
        flags |= ATTR_LAZY;



    /* type constraint data */

    tc = params[5];

    if ( SvOK(tc) ) {
        int tc_kind = SvIV(params[6]);
        SV *data = params[7];

        switch (tc_kind) {
            case tc_type:
                attr->tc_check.type = SvIV(data);
                break;
            case tc_stash:
                flags |= ATTR_TCREFCNT;
                attr->tc_check.sv = (SV *)gv_stashsv(data, 0);
                break;
            case tc_cv:
                flags |= ATTR_TCREFCNT;
                attr->tc_check.sv = SvRV(data);
                if ( SvTYPE(attr->tc_check.sv) != SVt_PVCV )
                    croak("compiled type constraint is not a coderef");
                break;
            default:
                croak("todo");
        }

        flags |= tc_kind;
    }

    

    /* default/builder data */

    if ( SvTRUE(params[10]) ) { /* has default */
        SV *sv = params[11];

        if ( SvROK(sv) ) {
            attr->def.sv = SvRV(sv);
            if ( SvTYPE(attr->def.sv) != SVt_PVCV )
                croak("compiled type constraint is not a coderef");
        } else {
            attr->def.sv = newSVsv(sv);
            sv_2mortal(attr->def.sv); /* in case of error soon, we refcnt inc it later after we're done checking params */
        }

        flags |= ( ATTR_DEFREFCNT | ( default_normal << ATTR_SHIFT_DEFAULT ) );
    } else if ( SvOK(params[12]) ) { /* builder */
        attr->def.sv = newSVsv(params[12]);
        flags |= ( ATTR_DEFREFCNT | ( default_builder << ATTR_SHIFT_DEFAULT ) );
    }



    attr->trigger = SvROK(params[6]) ? (CV *)SvRV(params[6]) : NULL;
    if ( attr->trigger && SvTYPE(attr->trigger) != SVt_PVCV )
        croak("trigger is not a coderef");

    attr->initializer = SvROK(params[7]) ? (CV *)SvRV(params[7]) : NULL;
    if ( attr->initializer && SvTYPE(attr->initializer) != SVt_PVCV )
        croak("initializer is not a coderef");



    /* now that we're done preparing/checking args and shit, so we finalize the
     * attr, increasing refcounts for any referenced data, and creating the CV
     * array */

    attr->flags = flags;

    /* copy the outer ref SV */
    attr->meta_attr       = newSVsv(params[0]);
    attr->type_constraint = newSVsv(tc);

    /* increase the refcount for auxillary structures */
    SvREFCNT_inc_simple_void(attr->trigger);
    SvREFCNT_inc_simple_void(attr->initializer);
    if ( flags & ATTR_TCREFCNT )  SvREFCNT_inc_simple_void_NN(attr->tc_check.sv);
    if ( flags & ATTR_DEFREFCNT ) SvREFCNT_inc_simple_void_NN(attr->def.sv);

    attr->slot_sv = newSVpvn_share(slot_pv, slot_len, slot_hash);
    attr->slot_u32 = slot_hash;

    attr->init_arg_sv = newSVpvn_share(init_arg_pv, init_arg_len, init_arg_hash);
    attr->init_arg_u32 = init_arg_hash;

    /* cross refs to CVs which use this struct */
    attr->cvs = newAV();
}

STATIC SV *new_mi (pTHX_ HV *stash, AV *attrs) {
    HV *mi_stash = gv_stashpvs("Moose::XS::Meta::Instance",0);
    SV *sv_ptr = newSViv(0);
    SV *obj = sv_2mortal(sv_bless(newRV_noinc(sv_ptr), mi_stash));
    MI *mi;
    const I32 num_attrs = av_len(attrs) + 1;

    Newxz(mi, 1, MI);

    /* set the pointer now, if we have any initialization errors it'll get
     * cleaned up because obj is mortal */
    sv_setiv(sv_ptr, PTR2IV(mi));

    Newxz(mi->attrs, num_attrs, ATTR);

    SvREFCNT_inc_simple_void_NN(stash);
    mi->stash = stash;

    mi->type = 0; /* nothing else implemented yet */

    /* initialize attributes */
    for ( ; mi->num_attrs < num_attrs; mi->num_attrs++ ) {
        SV **desc = av_fetch(attrs, mi->num_attrs, 0);

        if ( !desc || !*desc || !SvROK(*desc) || !(SvTYPE(SvRV(*desc)) == SVt_PVAV) ) {
            croak("Attribute descriptor has to be a hash reference");
        }

        init_attr(mi, &mi->attrs[mi->num_attrs], (AV *)SvRV(*desc));
    }

    return obj;
}

STATIC void delete_attr (pTHX_ ATTR *attr) {
    I32 i;
    SV **cvs = AvARRAY(attr->cvs);

    /* remove the pointers to this ATTR struct from all the the dependent CVs */
    for ( i = av_len(attr->cvs); i >= 0; i-- ) {
        CV *cv = (CV *)cvs[i];
        XSANY.any_i32 = 0;
    }

    SvREFCNT_dec(attr->cvs);
    SvREFCNT_dec(attr->slot_sv);
    SvREFCNT_dec(attr->type_constraint);
    if ( attr->flags & ATTR_TCREFCNT )  SvREFCNT_dec(attr->tc_check.sv);
    if ( attr->flags & ATTR_DEFREFCNT ) SvREFCNT_dec(attr->def.sv);
    SvREFCNT_dec(attr->initializer);
    SvREFCNT_dec(attr->trigger);
    SvREFCNT_dec(attr->meta_attr);
}

STATIC void delete_mi (pTHX_ MI *mi) {
    SvREFCNT_dec(mi->stash);

    while ( mi->num_attrs--) {
        ATTR *attr = &mi->attrs[mi->num_attrs];
        delete_attr(aTHX_ attr);
    }

    if ( mi->attrs ) Safefree(mi->attrs);
    Safefree(mi);
}




/* these functions call Perl-space for MOP methods, helpers etc */


/* wow, so much code for the equivalent of
 * $attr->associated_class->get_meta_instance */
STATIC SV *attr_to_meta_instance(pTHX_ SV *meta_attr) {
    dSP;
    I32 count;
    SV *mi;

    if ( !meta_attr )
        croak("No attr found in magic!");

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs(meta_attr);

    PUTBACK;
    count = call_pv("Moose::XS::attr_to_meta_instance", G_SCALAR);

    if ( count != 1 )
        croak("attr_to_meta_instance borked (%d args returned, expecting 1)", (int)count);

    SPAGAIN;
    mi = POPs;

    SvREFCNT_inc_simple_void(mi);

    PUTBACK;
    FREETMPS;
    LEAVE;

    return sv_2mortal(mi);
}

/* gets a class and an array of attr parameters */
STATIC SV *perl_mi_to_c_mi(pTHX_ SV *perl_mi) {
    dSP;
    I32 count;
    SV *mi;
    SV *class;
    SV *attrs;
    HV *stash;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs(perl_mi);

    PUTBACK;
    count = call_pv("Moose::XS::meta_instance_to_attr_descs", G_ARRAY);

    if ( count != 2 )
        croak("meta_instance_to_attr_descs borked (%d args returned, expecting 2)", (int)count);

    SPAGAIN;
    attrs = POPs;
    class = POPs;

    PUTBACK;

    stash = gv_stashsv(class, 0);

    mi = new_mi(aTHX_ stash, (AV *)SvRV(attrs));
    SvREFCNT_inc_simple_void_NN(mi);

    FREETMPS;
    LEAVE;

    return sv_2mortal(mi);
}



/* locate an ATTR for a MOP level attribute inside an MI */
STATIC ATTR *mi_find_attr(SV *mi_obj, SV *meta_attr) {
    I32 ix;
    MI *mi = INT2PTR(MI *, SvIV(SvRV(mi_obj)));

    for ( ix = 0; ix < mi->num_attrs; ix++ ) {
        if ( SvRV(mi->attrs[ix].meta_attr) == SvRV(meta_attr) ) {
            return &mi->attrs[ix];
        }
    }

    croak("Attr %x not found in meta instance of %s", (unsigned int)PTR2UV(SvRV(meta_attr)) /* SvPV_force_nomg(sv_2mortal(newSVsv(meta_attr))) */, HvNAME_get(mi->stash) );
    return NULL;
}

/* returns the ATTR for a CV:
 *
 * 1. get the Moose::Meta::Attribute using get_stashed_in_mg from the CV itself
 * 2. get the meta instance by calling $attr->associated_class->get_meta_instance
 * 3. get the MI by using get_stashed_in_mg from the meta instance, creating it if necessary
 * 4. search for the appropriate ATTR in the MI using mi_find_attr
 */
STATIC ATTR *get_attr(pTHX_ CV *cv) {
    SV *meta_attr = get_stashed_in_mg(aTHX_ (SV *)cv);
    SV *perl_mi = attr_to_meta_instance(aTHX_ meta_attr);
    SV *mi_obj = get_stashed_in_mg(aTHX_ SvRV(perl_mi));

    if (!mi_obj) {
        mi_obj = perl_mi_to_c_mi(aTHX_ perl_mi);
        stash_in_mg(aTHX_ SvRV(perl_mi), mi_obj);
    }

    return mi_find_attr(mi_obj, meta_attr);
}

/* Cache a pointer to the appropriate ATTR in the XSANY of the CV, using
 * get_attr */
STATIC ATTR *define_attr (pTHX_ CV *cv) {
    ATTR *attr = get_attr(aTHX_ cv);
    assert(attr);

    XSANY.any_i32 = PTR2IV(attr);

    SvREFCNT_inc_simple_void(cv);
    av_push( attr->cvs, (SV *)cv );

    return attr;
}







STATIC void weaken(pTHX_ SV *sv) {
#ifdef SvWEAKREF
	sv_rvweaken(sv); /* FIXME i think this might warn when weakening an already weak ref */
#else
	croak("weak references are not implemented in this release of perl");
#endif
}






/* meta instance protocol
 *
 * The slot functions don't change the refcount or copy (aliasing semantics)
 *
 * create_instance returns a new mortal */

STATIC SV *get_slot_lvalue(pTHX_ SV *self, ATTR *attr) {
    HE *he;

    assert(self);
    assert(SvROK(self));
    assert(SvTYPE(SvRV(self)) == SVt_PVHV);

    assert( ATTR_DUMB_INSTANCE(attr) );

    if ((he = hv_fetch_ent((HV *)SvRV(self), attr->slot_sv, 0, attr->slot_u32)))
        return HeVAL(he);
    else
        return NULL;
}

STATIC bool set_slot_value(pTHX_ SV *self, ATTR *attr, SV *value) {
    HE *he;

    assert(self);
    assert(SvROK(self));
    assert(SvTYPE(SvRV(self)) == SVt_PVHV);

    assert( ATTR_DUMB_INSTANCE(attr) );

    he = hv_store_ent((HV*)SvRV(self), attr->slot_sv, value, attr->slot_u32);

    return he != NULL;
}

STATIC bool has_slot_value(pTHX_ SV *self, ATTR *attr) {
    assert(self);
    assert(SvROK(self));
    assert(SvTYPE(SvRV(self)) == SVt_PVHV);

    assert( ATTR_DUMB_INSTANCE(attr) );

    return hv_exists_ent((HV *)SvRV(self), attr->slot_sv, attr->slot_u32);
}

STATIC SV *deinitialize_slot(pTHX_ SV *self, ATTR *attr) {
    assert(self);
    assert(SvROK(self));
    assert(SvTYPE(SvRV(self)) == SVt_PVHV);

    assert( ATTR_DUMB_INSTANCE(attr) );

    return hv_delete_ent((HV *)SvRV(self), attr->slot_sv, 0, attr->slot_u32);
}

STATIC SV *create_instance(pTHX_ MI *mi) {
    return sv_bless(sv_2mortal(newRV_noinc((SV *)newHV())), mi->stash);
}




/* Shared functionality for readers/writers/accessors, this roughly corresponds
 * to the methods of Moose::Meta::Attribute on the instance
 * (get_value/set_value, default value handling, etc)
 *
 * These functions return mortal copiess and save copies (handling refcounting). */

STATIC void attr_set_value(pTHX_ SV *self, ATTR *attr, SV *value);

STATIC SV *call_builder (pTHX_ SV *self, ATTR *attr) {
    SV *sv;
    dSP;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs(self);

    /* we invoke the builder as a stringified method. This will not work for
     * $obj->$coderef etc, for that we need to use 'default' */
    PUTBACK;
    call_method(SvPV_nolen(attr->def.sv), G_SCALAR);
    SPAGAIN;

    /* the value is a mortal with a refcount of 1, so we need to keep it around */
    sv = POPs;
    SvREFCNT_inc_simple_void(sv);

    PUTBACK;
    FREETMPS;
    LEAVE;

    return sv_2mortal(sv);
}


STATIC SV *get_default(pTHX_ SV *self, ATTR *attr) {
    switch ( ATTR_DEFAULT(attr) ) {
        case default_none:
            return NULL;
            break;
        case default_builder:
            return call_builder(aTHX_ self, attr);
            break;
        case default_normal:
            if ( SvROK(attr->def.sv) ) {
                printf("CV default\n");
                croak("todo");
            } else {
                printf("simple value\n");
                return sv_mortalcopy(attr->def.sv); /* will be copied by set for lazy, and by reader for both cases */
            }
            break;
        case default_type:
            croak("todo");
            break;
    }

    return NULL;
}

/* $attr->get_value($self), will vivify lazy values if needed
 * returns an alias to the sv that is copied in the reader/writer/accessor code
 * */
STATIC SV *attr_get_value(pTHX_ SV *self, ATTR *attr) {
    SV *value = get_slot_lvalue(aTHX_ self, attr);

    if ( value ) {
        return sv_mortalcopy(value);
    } else if ( ATTR_ISLAZY(attr) ) {
        value = get_default(aTHX_ self, attr);
        attr_set_value(aTHX_ self, attr, value);
        return value;
    }

    return NULL;
}

/* $attr->set_value($self) */
STATIC void attr_set_value(pTHX_ SV *self, ATTR *attr, SV *value) {
    SV *copy;

    if ( !value ) {
        /* FIXME croak if required ? */
        return;
    }

    if ( ATTR_TYPE(attr) ) {
        if ( !check_type_constraint(aTHX_ ATTR_TYPE(attr), attr->tc_check, attr->type_constraint, value) )
            croak("Bad param");
    }

    copy = newSVsv(value);

    if ( ATTR_ISWEAK(attr) && SvROK(copy) )
        weaken(aTHX_ copy);

    if ( !set_slot_value(aTHX_ self, attr, copy) ) {
        SvREFCNT_dec(copy);
        croak("Hash store failed.");
    }
}







/* Perl-space level functionality
 *
 * These subs are installed by new_sub's various aliases as the bodies of the
 * new XSUBs
 * */



/* This macro is used in the XS subs to set up the 'attr' variable.
 *
 * if XSANY is NULL then define_attr is called on the CV, to set the pointer
 * to the ATTR struct.
 * */
#define dATTR ATTR *attr = (XSANY.any_i32 ? INT2PTR(ATTR *, (XSANY.any_i32)) : define_attr(aTHX_ cv))


STATIC XS(reader);
STATIC XS(reader)
{
#ifdef dVAR
    dVAR;
#endif
    dXSARGS;
    dATTR;
    SV *value;

    if (items != 1)
        Perl_croak(aTHX_ "Usage: %s(%s)", GvNAME(CvGV(cv)), "self");

    SP -= items;

    value = attr_get_value(aTHX_ ST(0), attr);

    if (value) {
        ST(0) = value;
        XSRETURN(1);
    } else {
        XSRETURN_UNDEF;
    }
}

STATIC XS(writer);
STATIC XS(writer)
{
#ifdef dVAR
    dVAR;
#endif
    dXSARGS;
    dATTR;

    if (items != 2)
        Perl_croak(aTHX_ "Usage: %s(%s, %s)", GvNAME(CvGV(cv)), "self", "value");

    SP -= items;

    attr_set_value(aTHX_ ST(0), attr, ST(1));

    ST(0) = ST(1); /* return value */
    XSRETURN(1);
}

STATIC XS(accessor);
STATIC XS(accessor)
{
#ifdef dVAR
    dVAR;
#endif
    dXSARGS;
    dATTR;

    if (items < 1)
        Perl_croak(aTHX_ "Usage: %s(%s, [ %s ])", GvNAME(CvGV(cv)), "self", "value");

    SP -= items;

    if (items > 1) {
        attr_set_value(aTHX_ ST(0), attr, ST(1));
        ST(0) = ST(1); /* return value */
    } else {
        SV *value = attr_get_value(aTHX_ ST(0), attr);
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
    dATTR;

    if (items != 1)
        Perl_croak(aTHX_ "Usage: %s(%s)", GvNAME(CvGV(cv)), "self");

    SP -= items;

    if ( has_slot_value(aTHX_ ST(0), attr) )
        XSRETURN_YES;
    else
        XSRETURN_NO;
}

enum xs_body {
    xs_body_reader = 0,
    xs_body_writer,
    xs_body_accessor,
    xs_body_predicate,
    max_xs_body
};

STATIC XSPROTO ((*xs_bodies[])) = {
    reader,
    writer,
    accessor,
    predicate,
};

MODULE = Moose PACKAGE = Moose::XS
PROTOTYPES: ENABLE

CV *
new_sub(attr, name)
    INPUT:
        SV *attr;
        SV *name;
    PROTOTYPE: $;$
    ALIAS:
        new_reader    = xs_body_reader
        new_writer    = xs_body_writer
        new_accessor  = xs_body_accessor
        new_predicate = xs_body_predicate
    PREINIT:
        CV * cv;
    CODE:
        if ( ix >= max_xs_body )
            croak("Unknown Moose::XS body type");

        if ( !sv_isobject(attr) )
            croak("'attr' must be a Moose::Meta::Attribute");

        cv = newXS(SvOK(name) ? SvPV_nolen(name) : NULL, xs_bodies[ix], __FILE__);

        if (cv == NULL)
            croak("Oi vey!");

        /* associate CV with meta attr */
        stash_in_mg(aTHX_ (SV *)cv, attr);

        /* this will be set on first call */
        XSANY.any_i32 = 0;

        RETVAL = cv;
    OUTPUT:
        RETVAL


MODULE = Moose  PACKAGE = Moose::XS::Meta::Instance
PROTOTYPES: DISABLE

void
DESTROY(self)
    INPUT:
        SV *self;
    PREINIT:
        MI *mi = INT2PTR(MI *, SvIV(SvRV(self)));
    CODE:
        if ( mi )
            delete_mi(aTHX_ mi);


MODULE = Moose	PACKAGE = Moose::XS::TypeConstraints
PROTOTYPES: ENABLE

bool
_check_type(sv)
    INPUT:
        SV* sv
    ALIAS:
        Any = Any
        Item = Any
        Bool = Any
        Undef = Undef
        Defined = Defined
        Str = Str
        Value = Str
        Num = Num
        Int = Int
        GlobRef = GlobRef
        ArrayRef = ArrayRef
        HashRef = HashRef
        CodeRef = CodeRef
        Ref = Ref
        ScalarRef = ScalarRef
        FileHandle = FileHandle
        RegexpRef = RegexpRef
        Object = Object
        Role = Role
        ClassName = ClassName
    CODE:
        RETVAL = check_sv_type(ix, sv);
    OUTPUT:
        RETVAL

bool
ObjectOfType(sv, class)
    INPUT:
        SV* sv
        SV* class
    PREINIT:
        HV *stash = gv_stashsv(class, 0);
    CODE:
        RETVAL = check_sv_class(aTHX_ stash, sv);
    OUTPUT:
        RETVAL
