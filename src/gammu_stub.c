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

#define Error_val(v) (Int_val(v) + 1)

/************************************************************************/
/* Debuging handling */

CAMLprim
value gammu_caml_ErrorString(value verr)
{
  CAMLparam1(verr);
  const char *msg = GSM_ErrorString(Error_val(verr));
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

/************************************************************************/
/* State machine */

#define StateMachine_val(v) (*(GSM_StateMachine **) Data_Custom_val(v))

static void gammu_caml_sm_finalize(value state_machine)
{
  GSM_FreeStateMachine(STATE_MACHINE_VAL(state_machine));
}

static struct custom_operations gammu_caml_sm_ops = {
  "be.umons.ml-gammu.state_machine",
  gammu_caml_sm_finalize,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

static value alloc_StateMachine()
{
  return alloc_custom(&gammu_caml_sm_ops, sizeof(StateMachine *), 1, 1000);
}

static value Val_StateMachine(StateMachine *state_machine)
{
  CAMLlocal1(res);
  res = alloc_StateMachine();
  StateMachine_val(res) = state_machine;
  return res;
}

value Val_Config(GSM_Config cfg)
{
  CAMLlocal1(res);
  res = caml_alloc(14, 0);
  Store_field(res, 0, caml_copy_string(config.model));
  Store_field(res, 1, caml_copy_string(config.debug_level));
  Store_field(res, 2, caml_copy_string(config.device));
  Store_field(res, 3, caml_copy_string(config.connection));
  Store_field(res, 4, Val_bool(config.sync_time));
  Store_field(res, 5, Val_bool(config.lock_device));
  Store_field(res, 6, caml_copy_string(config.debug_file));
  Store_field(res, 7, Val_bool(config.start_info));
  Store_field(res, 8, Val_bool(config.use_global_debug_file));
  Store_field(res, 9, caml_copy_string(config.text_reminder));
  Store_field(res, 10, caml_copy_string(config.text_reminder));
  Store_field(res, 11, caml_copy_string(config.text_meeting));
  Store_field(res, 12, caml_copy_string(config.text_birthday));
  Store_field(res, 13, caml_copy_string(config.text_memo));
  return res;
}

GSM_Config Config_val(value vconfig)
{
  GSM_Config config;
  config.model = String_val(Field(vconfig, 0));
  config.debug_level = String_val(Field(vconfig, 1));
  config.device = String_val(Field(vconfig, 2));
  config.connection = String_val(Field(vconfig, 3));
  config.sync_time = Bool_val(Field(vconfig, 4));
  config.lock_device = Bool_val(Field(vconfig, 5));
  config.debug_file = String_val(Field(vconfig, 6));
  config.start_info = Bool_val(Field(vconfig, 7));
  config.use_global_debug_file = Bool_val(Field(vconfig, 8));
  config.text_reminder = String_val(Field(vconfig, 9));
  config.text_meeting = String_val(Field(vconfig, 10));
  config.text_call = String_val(Field(vconfig, 11));
  config.text_birthday = String_val(Field(vconfig, 12));
  config.text_memo = String_val(Field(vconfig, 13));
  return config;
}

#define ConnectionType_val(v) (Int_val(v) + 1)

CAMLprim
value gammu_caml_GetDebug(value s)
{
  CAMLparam1(s);
  CAMLreturn((value) GSM_GetDebug());
}

CAMLprim
void gammu_caml_InitLocales(value path)
{
  CAMLparam1(path);
  GSM_InitLocales(String_val(path));
  CAMLreturn0;
}

CAMLprim
void gammu_caml_InitDefaultLocales()
{
  CAMLreturn0;
}

CAMLprim
value gammu_caml_CreateStateMachine()
{
  CAMLreturn(Val_StateMachine(GSM_AllocStateMachine()));
}

CAMLprim
void gammu_caml_FindGammuRC(value path)
{
  CAMLparam1(path);
  GSM_FindGammuRC(String_val(path));
  CAMLreturn0;
}

CAMLprim
void gammu_caml_FindDefaultGammuRC()
{
  CAMLreturn0;
}

CAMLprim
value gammu_caml_ReadConfig(value cfg_info, value num)
{
  CAMLreturn(Val_Config(GSM_ReadConfig(INI_Section_val(cfg_info), Int_val(num))));
}

CAMLprim
value gammu_caml_GetConfig(value s, value num)
{
  CAMLparam2(s, num);
  CAMLreturn(Val_Config(GSM_GetConfig(StateMachine_val(s), Int_val(num))));
}

CAMLexport
void gammu_caml_PushConfig(value s, value cfg)
{
  CAMLparam2(s, cfg);
  int cfg_num = GSM_GetConfigNum(StateMachine_val(s));
  GSM_Config *dest_cfg = GSM_GetConfig(StateMachine_val(s), cfg_num);
  if (cfg != NULL)
    dest_cfg = Config_val(cfg);
  /* else
       To many configs (more than MAX_CONFIG_NUM (=5))
  */
  CAMLreturn0;
}

CAMLexport
void gammu_caml_RemoveConfig(value s)
{
  CAMLparam1(s);
  GSM_StateMachine* sm = StateMachine_val(s);
  int cfg_num = GSM_GetConfigNum(sm);
  if (cfg_num > 0)
    GSM_SetConfigNum(sm, cfg_num - 1);
  /* else
     Empty stack, can't remove
  */
  CAMLreturn0;
}
  
CAMLprim
value gammu_caml_GetConfigNum(value s)
{
  CAMLparam1(s);
  CAMLreturn(Val_int( GSM_SetConfigNum(StateMachine_val(s)) ));
}

CAMLexport
void gammu_caml_InitConnection(value s, value reply_num)
{
  CAMLparam2(s, reply_num);
  GSM_InitConnection(StateMachine_val(s), Int_val(reply_num));
}

CAMLexport
void gammu_caml_InitConnectionLog(value s, value reply_num, value log_func)
{
  CAMLparam3(s, reply_num, log_func);
  GSM_InitConnectionLog(StateMachine_val(s),
                        Int(val(reply_num)),
                        Code_val(log_func));
  CAMLreturn0;
}

/************************************************************************/
/* Security related operations with phone. */

