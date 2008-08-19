#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* FIXME
 * needs to be made into Moose::XS::Meta::Instance and Meta::Slot for the
 * metadata, with a proper destructor. XSANY still points to this struct, but
 * it is shared by all functions of the same type.
 *
 * Instance contains SvSTASH, and ATTR slots[]
 *
 * On recreation of the meta instance we refresh the ATTR value of all the CVs
 * we installed
 *
 * need a good way to handle time between invalidate and regeneration (just
 * check XSANY and call get_meta_instance if null?)
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
 * for a constructor we have ATTR *attrs, and iterate that, removing init_arg
 * we can preallocate the structure to the right size (maybe even with the
 * right HEs?), and do various other prehashing hacks to gain speed
 * */

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



typedef enum {
    Any = 0,
    Item,
        Bool,
        Maybe, /* [`a] */
        Undef,
        Defined,
            Value,
                Num,
                    Int,
                Str,
                    ClassName,
            Ref,
                ScalarRef,
                ArrayRef, /* [`a] */
                HashRef, /* [`a] */
                CodeRef,
                RegexpRef,
                GlobRef,
                    FileHandle,
                Object,
                    Role,

    /* XS only types */
    Class,

    max_TC
} TC;

typedef union {
    TC type;
    CV *cv;
    HV *stash;
    OP *op;
} TC_CHECK;

typedef enum {
    tc_none = 0,
    tc_type,
    tc_cv,
    tc_stash,
    tc_op,
} tc_kind;

typedef union {
    char *builder;
    SV *value;
    CV *sub;
    OP *op;
    U32 type;
} DEFAULT;

typedef enum {
    default_none = 0,
    default_type,
    default_builder,
    default_value,
    default_sub,
    default_op,
} default_kind;

typedef struct {
    /* the meta instance struct */
    struct mi *mi;

    U32 flags; /* slot type, TC behavior, coerce, weaken, (no default | default, builder + lazy), auto_deref */

    /* slot access fields */
    SV *slot_sv; /* value of the slot (slot name presumably) */
    U32 slot_u32; /* for optimized access (precomputed hash or otherr) */

    DEFAULT def; /* cv, value or other, depending on flags */

    TC_CHECK tc_check; /* cv, value or other, dependidng on flags */
    SV *type_constraint; /* meta attr */

    CV *initializer;
    CV *trigger;

    SV *attr; /* the meta attr object */
    AV *cvs; /* CVs which use this attr */
} ATTR;

/* slot flags:
 * instance           reading  writing
 * 00000000 00000000 00000000 00000000
 *                              ^      trigger
 *                               ^     weak
 *                                 ^^^ tc_kind
 *                                ^    coerce
 *                        ^^^          default_kind
 *                       ^             lazy
 *                 ^                   required
 * ^^^^^^^                             if 0 then nothing special (just hash)? FIXME TBD
 */

#define ATTR_INSTANCE_MASK 0xff000000
#define ATTR_READING_MASK  0x0000ff00
#define ATTR_WRITING_MASK  0x000000ff

#define ATTR_MASK_TYPE 0x7

#define ATTR_MASK_DEFAULT 0x700
#define ATTR_SHIFT_DEAFULT 8

#define ATTR_LAZY 0x800

#define ATTR_COERCE 0x08
#define ATTR_WEAK 0x10
#define ATTR_TRIGGER 0x10

#define ATTR_ISWEAK(attr) ( attr->flags & ATTR_WEAK )
#define ATTR_ISLAZY(attr) ( attr->flags & ATTR_LAZY )
#define ATTR_ISCOERCE(attr) ( attr->flags & ATTR_COERCE )

#define ATTR_TYPE(f) ( attr->flags & 0x7 )
#define ATTR_DEFAULT(f) ( ( attr->flags & ATTR_MASK_DEFAULT ) >> ATTR_SHIFT_DEFAULT )

#define ATTR_DUMB_READER(attr) !ATTR_IS_LAZY(attr)
#define ATTR_DUMB_WRITER(attr) ( ( attr->flags & ATTR_WRITING_MASK ) == 0 )
#define ATTR_DUMB_INSTANCE(attr) ( ( attr->flags & ATTR_INSTANCE_MASK ) == 0 )

#define dATTR ATTR *attr = (INT2PTR(ATTR *, (XSANY.any_i32 || define_attr(aTHX_ cv))))


/* FIXME define a vtable that does call_sv */
typedef struct {
    SV * (*get)(pTHX_ SV *self, ATTR *attr);
    void (*set)(pTHX_ SV *self, ATTR *attr, SV *value);
    bool * (*has)(pTHX_ SV *self, ATTR *attr);
    SV * (*delete)(pTHX_ SV *self, ATTR *attr);
} instance_vtbl;


typedef enum {
    hash = 0,

    /* these are not yet implemented */
    array,
    fptr,
    cv,
    judy,
} instance_types;

typedef struct mi {
    SV *associated_metaclass;
    HV *stash;

    /* slot access method */
    instance_types type;
    instance_vtbl *vtbl;

    /* attr descriptors */
    I32 num_attrs;
    ATTR *attrs;
} MI;


STATIC void init_attr (MI *mi, ATTR *attr, HV *desc) {
    U32 hash;
    STRLEN len;
    SV **key = hv_fetchs(desc, "key", 0);
    SV **meta_attr = hv_fetchs(desc, "meta", 0);
    char *pv;

    if ( !meta_attr ) croak("'meta' is required");

    attr->attr = *meta_attr;

    attr->mi = mi;

    attr->flags = 0;


    /* if type == hash */
    /* prehash the key */
    if ( !key ) croak("'key' is required");

    pv = SvPV(*key, len);

    PERL_HASH(hash, pv, len);

    attr->slot_sv = newSVpvn_share(pv, len, hash);
    attr->slot_u32 = hash;

    attr->def.type = 0;

    attr->tc_check.type = 0;
    attr->type_constraint = NULL;


    attr->initializer = NULL;
    attr->trigger = NULL;

    /* cross refs to CVs which use this struct */
    attr->cvs = newAV();
}

STATIC MI *new_mi (pTHX_ HV *stash, SV *meta, AV *attrs) {
    MI *mi;
    I32 ix;
    const I32 num = av_len(attrs) + 1;

    Newx(mi, 1, MI);

    SvREFCNT_inc_simple(stash);
    mi->stash = stash;

    SvREFCNT_inc_simple(meta);
    mi->associated_metaclass = meta;

    mi->type = 0; /* nothing else implemented yet */

    /* initialize attributes */
    mi->num_attrs = num;
    Newx(mi->attrs, num, ATTR);
    for ( ix = 0; ix < mi->num_attrs; ix++ ) {
        SV **desc = av_fetch(attrs, ix, 0);

        if ( !desc || !SvROK(*desc) || !(SvTYPE(SvRV(*desc)) == SVt_PVHV) )
            croak("Attribute descriptor has to be a hash reference");

        init_attr(mi, &mi->attrs[ix], (HV *)SvRV(*desc));
    }

    return mi;
}

STATIC SV *get_meta_attr_from_mg(pTHX_ CV *cv) {
    MAGIC *mg, *moremagic;

    if (SvTYPE(cv) >= SVt_PVMG) {
        for (mg = SvMAGIC(cv); mg; mg = mg->mg_moremagic) {
            if ((mg->mg_type == PERL_MAGIC_ext) && (mg->mg_virtual == &null_mg_vtbl))
                break;
        }
        if (mg)
            return mg->mg_obj;
    }

    croak("No attr found in magic!");
    return NULL;
}

STATIC ATTR *get_attr(pTHX_ CV *cv) {
    SV *meta_attr = get_meta_attr_from_mg(aTHX_ cv);

#if 0
    my $mi = $meta_attr->associated_metaclass->get_meta_instance;
    my @attrs = map {
        {
            meta => $_,
            key =>  ($_->slots)[0],
        },
    } @{ $mi->attributes };
#else
    croak("todo");
#endif

    return NULL;
}

STATIC ATTR *define_attr (pTHX_ CV *cv) {
    ATTR *attr = get_attr(aTHX_ cv);
    assert(attr);

    XSANY.any_i32 = PTR2IV(attr);
    av_push( attr->cvs, cv );

    return attr;
}

STATIC void weaken(pTHX_ SV *sv) {
#ifdef SvWEAKREF
	sv_rvweaken(sv); /* FIXME i think this might warn when weakening an already weak ref */
#else
	croak("weak references are not implemented in this release of perl");
#endif
}


/* meta instance protocol */

STATIC SV *get_slot_value(pTHX_ SV *self, ATTR *attr) {
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

STATIC void set_slot_value(pTHX_ SV *self, ATTR *attr, SV *value) {
    HE *he;

    assert(self);
    assert(SvROK(self));
    assert(SvTYPE(SvRV(self)) == SVt_PVHV);

    assert( ATTR_DUMB_INSTANCE(attr) );

    SvREFCNT_inc(value);

    he = hv_store_ent((HV*)SvRV(self), attr->slot_sv, value, attr->slot_u32);
    if (he != NULL) {
        if ( ATTR_ISWEAK(attr) )
            weaken(aTHX_ HeVAL(he)); /* actually only needed once at HE creation time */
    } else {
        croak("Hash store failed.");
    }
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


/* simple high level api */

STATIC XS(getter);
STATIC XS(getter)
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

    assert( ATTR_DUMB_READER(attr) );

    value = get_slot_value(aTHX_ ST(0), attr);

    if (value) {
        ST(0) = sv_mortalcopy(value); /* mortalcopy because $_ .= "blah" for $foo->bar */
        XSRETURN(1);
    } else {
        XSRETURN_UNDEF;
    }
}

STATIC XS(setter);
STATIC XS(setter)
{
#ifdef dVAR
    dVAR;
#endif
    dXSARGS;
    dATTR;

    if (items != 2)
        Perl_croak(aTHX_ "Usage: %s(%s, %s)", GvNAME(CvGV(cv)), "self", "value");

    SP -= items;

    assert( ATTR_DUMB_WRITER(attr) );

    set_slot_value(aTHX_ ST(0), attr, ST(1));

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
        assert( ATTR_DUMB_READER(attr) );
        set_slot_value(aTHX_ ST(0), attr, ST(1));
        ST(0) = ST(1); /* return value */
    } else {
        assert( ATTR_DUMB_WRITER(attr) );
        SV *value = get_slot_value(aTHX_ ST(0), attr);
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
    xs_body_getter = 0,
    xs_body_setter,
    xs_body_accessor,
    xs_body_predicate,
    max_xs_body
};

STATIC XSPROTO ((*xs_bodies[])) = {
    getter,
    setter,
    accessor,
    predicate,
};

MODULE = Moose PACKAGE = Moose::XS

CV *
new_sub(attr, name)
    INPUT:
        SV *attr;
        SV *name;
    ALIAS:
        new_getter    = xs_body_getter
        new_setter    = xs_body_setter
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
        (void)Perl_sv_magicext(aTHX_ (SV *)cv, attr, PERL_MAGIC_ext, &null_mg_vtbl, STR_WITH_LEN("Moose::Meta::Attribute") );

        /* this will be set on first call */
        XSANY.any_i32 = 0;

        RETVAL = cv;
    OUTPUT:
        RETVAL


