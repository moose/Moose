/*
 *   full definition of built-in type constraints (ware in Moose::Util::TypeConstraints::OptimizedConstraints)
 */

#define PERL_NO_GET_CONTEXT
#include "mop.h"
#include "moose.h"

#if PERL_BCDVERSION >= 0x5008005
#define LooksLikeNumber(sv) looks_like_number(sv)
#else
#define LooksLikeNumber(sv) ( SvPOKp(sv) ? looks_like_number(sv) : SvNIOKp(sv) )
#endif

#ifndef SvRXOK
#define SvRXOK(sv) (SvROK(sv) && SvMAGICAL(SvRV(sv)) && mg_find(SvRV(sv), PERL_MAGIC_qr))
#endif


int
moose_tc_check(pTHX_ moose_tc const tc, SV* const sv) {
    switch(tc){
    case MOOSE_TC_ANY:        return moose_tc_Any(aTHX_ sv);
    case MOOSE_TC_ITEM:       return moose_tc_Any(aTHX_ sv);
    case MOOSE_TC_UNDEF:      return moose_tc_Undef(aTHX_ sv);
    case MOOSE_TC_DEFINED:    return moose_tc_Defined(aTHX_ sv);
    case MOOSE_TC_BOOL:       return moose_tc_Bool(aTHX_ sv);
    case MOOSE_TC_VALUE:      return moose_tc_Value(aTHX_ sv);
    case MOOSE_TC_REF:        return moose_tc_Ref(aTHX_ sv);
    case MOOSE_TC_STR:        return moose_tc_Str(aTHX_ sv);
    case MOOSE_TC_NUM:        return moose_tc_Num(aTHX_ sv);
    case MOOSE_TC_INT:        return moose_tc_Int(aTHX_ sv);
    case MOOSE_TC_SCALAR_REF: return moose_tc_ScalarRef(aTHX_ sv);
    case MOOSE_TC_ARRAY_REF:  return moose_tc_ArrayRef(aTHX_ sv);
    case MOOSE_TC_HASH_REF:   return moose_tc_HashRef(aTHX_ sv);
    case MOOSE_TC_CODE_REF:   return moose_tc_CodeRef(aTHX_ sv);
    case MOOSE_TC_GLOB_REF:   return moose_tc_GlobRef(aTHX_ sv);
    case MOOSE_TC_FILEHANDLE: return moose_tc_FileHandle(aTHX_ sv);
    case MOOSE_TC_REGEXP_REF: return moose_tc_RegexpRef(aTHX_ sv);
    case MOOSE_TC_OBJECT:     return moose_tc_Object(aTHX_ sv);
    case MOOSE_TC_CLASS_NAME: return moose_tc_ClassName(aTHX_ sv);
    case MOOSE_TC_ROLE_NAME:  return moose_tc_RoleName(aTHX_ sv);
    default:
        /* custom type constraints */
        NOOP;
    }

    croak("Custom type constraint is not yet implemented");
    return FALSE; /* not reached */
}


/*
    The following type check functions return an integer, not a bool, to keep them simple,
    so if you assign these return value to bool variable, you must use "expr ? TRUE : FALSE".
*/

int
moose_tc_Any(pTHX_ SV* const sv PERL_UNUSED_DECL) {
    assert(sv);
    return TRUE;
}

int
moose_tc_Bool(pTHX_ SV* const sv) {
    assert(sv);
    if(SvOK(sv)){
        if(SvIOKp(sv)){
            return SvIVX(sv) == 1 || SvIVX(sv) == 0;
        }
        else if(SvNOKp(sv)){
            return SvNVX(sv) == 1.0 || SvNVX(sv) == 0.0;
        }
        else if(SvPOKp(sv)){ /* "" or "1" or "0" */
            return SvCUR(sv) == 0
                || ( SvCUR(sv) == 1 && ( SvPVX(sv)[0] == '1' || SvPVX(sv)[0] == '0' ) );
        }
        else{
            return FALSE;
        }
    }
    else{
        return TRUE;
    }
}

int
moose_tc_Undef(pTHX_ SV* const sv) { /* Who use this? */
    assert(sv);
    return !SvOK(sv);
}

int
moose_tc_Defined(pTHX_ SV* const sv) {
    assert(sv);
    return SvOK(sv);
}

int
moose_tc_Value(pTHX_ SV* const sv) {
    assert(sv);
    return SvOK(sv) && !SvROK(sv);
}

int
moose_tc_Num(pTHX_ SV* const sv) {
    assert(sv);
    return LooksLikeNumber(sv);
}

int
moose_tc_Int(pTHX_ SV* const sv) {
    assert(sv);
    if(SvIOKp(sv)){
        return TRUE;
    }
    else if(SvNOKp(sv)){
        NV const nv = SvNVX(sv);
        return nv > 0 ? (nv == (NV)(UV)nv) : (nv == (NV)(IV)nv);
    }
    else if(SvPOKp(sv)){
        int const num_type = grok_number(SvPVX(sv), SvCUR(sv), NULL);
        if(num_type){
            return !(num_type & IS_NUMBER_NOT_INT);
        }
    }
    return FALSE;
}

int
moose_tc_Str(pTHX_ SV* const sv) {
    assert(sv);
    return SvOK(sv) && !SvROK(sv);
}

int
moose_tc_ClassName(pTHX_ SV* const sv){ 
    assert(sv);
    return mop_is_class_loaded(aTHX_ sv);
}

int
moose_tc_RoleName(pTHX_ SV* const sv) {
    assert(sv);
    if(mop_is_class_loaded(aTHX_ sv)){
        int ok;
        SV* meta;
        dSP;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        XPUSHs(sv);
        PUTBACK;
        call_pv("Class::MOP::get_metaclass_by_name", G_SCALAR);
        SPAGAIN;
        meta = POPs;
        PUTBACK;

        ok = mop_is_instance_of(aTHX_ meta, newSVpvs_flags("Moose::Meta::Role", SVs_TEMP));

        FREETMPS;
        LEAVE;

        return ok;
    }
    return FALSE;
}

int
moose_tc_Ref(pTHX_ SV* const sv) {
    assert(sv);
    return SvROK(sv);
}

int
moose_tc_ScalarRef(pTHX_ SV* const sv) {
    assert(sv);
    return SvROK(sv) && !SvOBJECT(SvRV(sv)) && (SvTYPE(SvRV(sv)) <= SVt_PVLV && !isGV(SvRV(sv)));
}

int
moose_tc_ArrayRef(pTHX_ SV* const sv) {
    assert(sv);
    return SvROK(sv) && !SvOBJECT(SvRV(sv)) && SvTYPE(SvRV(sv)) == SVt_PVAV;
}

int
moose_tc_HashRef(pTHX_ SV* const sv) {
    assert(sv);
    return SvROK(sv) && !SvOBJECT(SvRV(sv)) && SvTYPE(SvRV(sv)) == SVt_PVHV;
}

int
moose_tc_CodeRef(pTHX_ SV* const sv) {
    assert(sv);
    return SvROK(sv)  && !SvOBJECT(SvRV(sv))&& SvTYPE(SvRV(sv)) == SVt_PVCV;
}

int
moose_tc_RegexpRef(pTHX_ SV* const sv) {
    assert(sv);
    return SvRXOK(sv);
}

int
moose_tc_GlobRef(pTHX_ SV* const sv) {
    assert(sv);
    return SvROK(sv) && !SvOBJECT(SvRV(sv)) && isGV(SvRV(sv));
}

int
moose_tc_FileHandle(pTHX_ SV* const sv) {
    GV* gv;
    assert(sv);

    gv = (GV*)(SvROK(sv) ? SvRV(sv) : sv);
    if(isGV(gv)){
        IO* const io = GvIO(gv);

        return io && ( IoIFP(io) || SvTIED_mg((SV*)io, PERL_MAGIC_tiedscalar) );
    }

    return mop_is_instance_of(aTHX_ sv, newSVpvs_flags("IO::Handle", SVs_TEMP));
}

int
moose_tc_Object(pTHX_ SV* const sv) {
    assert(sv);
    return SvROK(sv) && SvOBJECT(SvRV(sv)) && !SvRXOK(sv);
}

