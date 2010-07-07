/* File: gammu_stub.c

   Copyright (C) 2010

     Christophe Troestler <Christophe.Troestler@umons.ac.be>
     Pierre Hauweele <Pierre.Hauweele@student.umons.ac.be>
     Noémie Meunier <Noemie.Meunier@student.umons.ac.be>
     WWW: http://math.umons.ac.be/an/software/

   This library is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License version 3 or
   later as published by the Free Software Foundation.  See the file
   LICENCE for more details.

   This library is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the file
   LICENSE for more details. */

#include <gammu.h>

#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/fail.h>
#include <caml/custom.h>
#include <caml/intext.h>

#define ERROR_VAL(v) (Int_val(v) + 1)

CAMLprim
value gammu_caml_ErrorString(value verr)
{
  CAMLparam1(verr);
  const char* msg = GSM_ErrorString(ERROR_VAL(verr));
  CAMLreturn caml_copy_string(msg);
}

// TODO:?? CAMLPrim vs CAMLexport ?
CAMLprim
value gammu_caml_GetGlobalDebug()
{
  /*value res = caml_alloc(1, Abstract_tag);
  GSM_Debug_Info* di = GSM_GetGlobalDebug();
  Field(res, 0) = (value) di
  CAMLreturn(res);*/

  CAMLreturn ((value) GSM_GetGlobalDebug());
}

CAMLexport
void gammu_caml_SetDebugGlobal(value info, value privdi)
{
  CAMLparam2(info, privdi);
  GSM_SetDebugGlobal(Bool_val(info), (GSM_Debug_Info*) privdi);
  CAMLreturn0;
}

CAMLexport
void gammu_caml_SetDebugFileDescriptor(value fd, value closable, value di)
{
  CAMLparam3(fd, closable, di);
  GSM_SetDebugFileDescriptor(Int_val(fd), Bool_val(closable), (GSM_Debug_Info*) di);
  CAMLreturn0;
}

CAMLexport
void gammu_caml_SetDebugLevel(value level, value di)
{
  CAMLparam2(level, di);
  GSM_SetDebugLevel(String_val(level), (GSM_Debug_Info*) di);
  CAMLreturn0;
}
