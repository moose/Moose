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
