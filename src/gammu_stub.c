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

/************************************************************************/
/* Debuging handling */

CAMLprim
value gammu_caml_ErrorString(value verr)
{
  CAMLparam1(verr);
  const char *msg = GSM_ErrorString(ERROR_VAL(verr));
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
void gammu_caml_SetDebugGlobal(value info, value di)
{
  CAMLparam2(info, di);
  GSM_SetDebugGlobal(Bool_val(info), (GSM_Debug_Info *) di);
  CAMLreturn0;
}

CAMLexport
void gammu_caml_SetDebugFileDescriptor(value fd, value closable, value di)
{
  CAMLparam3(fd, closable, di);
  GSM_SetDebugFileDescriptor(Int_val(fd),
                             Bool_val(closable),
                             (GSM_Debug_Info *) di);
  CAMLreturn0;
}

CAMLexport
void gammu_caml_SetDebugLevel(value level, value di)
{
  CAMLparam2(level, di);
  GSM_SetDebugLevel(String_val(level), (GSM_Debug_Info *) di);
  CAMLreturn0;
}

/************************************************************************/
/* INI files */

#define INI_Section_val(v) (*(INI_Section **) (Data_Custom_Val(v))

static void gammu_caml_ini_section_finalize(value ini_section)
{
  INI_Free(INI_Section_val(ini_section));
}

static struct custom_operations gammu_caml_ini_section_ops = {
  "be.umons.ml-gammu.ini_section",
  gammu_caml_ini_section_finalize,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

static value alloc_INI_Section()
{
  return alloc_custom(&gammu_caml_ini_section_ops, sizeof(INI_Section *),
                      1, 1000);
}

static value Val_INI_Section(INI_Section *ini_section)
{
  CAMLlocal1(res); // needed ?
  res = alloc_INI_Section();
  INI_Section_val(res) = ini_section;
  return res;
}

CAMLprim
value gammu_caml_ReadFile(value file_name, value unicode)
{
  CAMLparam2(filename, unicode);
  
  INI_Section *cfg;
 
  INI_ReadFile(String_val(filename), Bool_val unicode, &cfg);
}
