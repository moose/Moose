#include "moose.h"

void
moose_throw_error(SV* const metaobject, SV* const data, const char* const fmt, ...){
    dTHX;
    va_list args;
    SV* message;

    assert(metaobject);
    assert(fmt);

    va_start(args, fmt);
    message = vnewSVpvf(fmt, &args);
    va_end(args);

    {
        dSP;
        PUSHMARK(SP);
        EXTEND(SP, 4);

        PUSHs(metaobject);
        mPUSHs(message);

        mPUSHs(newSVpvs("depth"));
        mPUSHi(-1);

        if(data){
            EXTEND(SP, 2);
            mPUSHs(newSVpvs("data"));
            PUSHs(data);
        }
        PUTBACK;
        call_method("throw_error", G_VOID);
        croak("throw_error() did not throw the error (%"SVf")", message);
    }
}

MODULE = Moose   PACKAGE = Moose::Util::TypeConstraints::OptimizedConstraints

void
Item(SV* sv = &PL_sv_undef)
ALIAS:
    Any        = MOOSE_TC_ANY
    Item       = MOOSE_TC_ITEM
    Undef      = MOOSE_TC_UNDEF
    Defined    = MOOSE_TC_DEFINED
    Bool       = MOOSE_TC_BOOL
    Value      = MOOSE_TC_VALUE
    Ref        = MOOSE_TC_REF
    Str        = MOOSE_TC_STR
    Num        = MOOSE_TC_NUM
    Int        = MOOSE_TC_INT
    ScalarRef  = MOOSE_TC_SCALAR_REF
    ArrayRef   = MOOSE_TC_ARRAY_REF
    HashRef    = MOOSE_TC_HASH_REF
    CodeRef    = MOOSE_TC_CODE_REF
    GlobRef    = MOOSE_TC_GLOB_REF
    FileHandle = MOOSE_TC_FILEHANDLE
    RegexpRef  = MOOSE_TC_REGEXP_REF
    Object     = MOOSE_TC_OBJECT
    ClassName  = MOOSE_TC_CLASS_NAME
    RoleName   = MOOSE_TC_ROLE_NAME
CODE:
    SvGETMAGIC(sv);
    ST(0) = boolSV( moose_tc_check(aTHX_ ix, sv) );
    XSRETURN(1);

MODULE = Moose   PACKAGE = Moose::Meta::Method::Accessor

PROTOTYPES: DISABLE

CV*
_generate_accessor_method_xs(SV* self, void* instance_vtbl)
CODE:
    RETVAL = moose_instantiate_xs_accessor(aTHX_ self, moose_xs_accessor, instance_vtbl);
OUTPUT:
    RETVAL

CV*
_generate_reader_method_xs(SV* self, void* instance_vtbl)
CODE:
    RETVAL = moose_instantiate_xs_accessor(aTHX_ self, moose_xs_reader, instance_vtbl);
OUTPUT:
    RETVAL

CV*
_generate_writer_method_xs(SV* self, void* instance_vtbl)
CODE:
    RETVAL = moose_instantiate_xs_accessor(aTHX_ self, moose_xs_writer, instance_vtbl);
OUTPUT:
    RETVAL
