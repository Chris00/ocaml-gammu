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
  CAMLreturn(caml_copy_string(msg));
}

// TODO:?? CAMLPrim vs CAMLexport ?
CAMLprim
value gammu_caml_GetGlobalDebug()
{
  /*value res = caml_alloc(1, Abstract_tag);
  GSM_Debug_Info* di = GSM_GetGlobalDebug();
  Field(res, 0) = (value) di
  CAMLreturn(res);*/

  CAMLreturn((value) GSM_GetGlobalDebug());
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

CAMLprim
GSM_Config GSM_Config_val(value vconfig)
{
  GSM_Config config;
  config.model = String_val(FIELD(vconfig, 0));
  config.debug_level = String_val(FIELD(vconfig, 1));
  config.device = String_val(FIELD(vconfig, 2));
  config.connection = String_val(FIELD(vconfig, 3));
  config.sync_time = Bool_val(FIELD(vconfig, 4));
  config.lock_device = Bool_val(FIELD(vconfig, 5));
  config.debug_file = String_val(FIELD(vconfig, 6));
  config.start_info = Bool_val(FIELD(vconfig, 7));
  config.use_global_debug_file = Bool_val(FIELD(vconfig, 8));
  config.text_reminder = String_val(FIELD(vconfig, 9));
  config.text_meeting = String_val(FIELD(vconfig, 10));
  config.text_call = String_val(FIELD(vconfig, 11));
  config.text_birthday = String_val(FIELD(vconfig, 12));
  config.text_memo = String_val(FIELD(vconfig, 13));
}

#define ConnectionType_val(v) (Int_val(v) + 1)
#define Val_ConnectionType(v) (Val_int(v) - 1)

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
  CAMLreturn((value) GSM_ReadConfig(INI_Section_val(cfg_info), Int_val(num)));
}

CAMLprim
value gammu_caml_GetConfig(value s, value num)
{
  CAMLparam2(s, num);
  CAMLreturn((value) GSM_GetConfig(StateMachine_val(s), Int_val(num)));
}



CAMLprim
void gammu_caml_TerminateConnection(value s)
{
  CAMLparam1(s);
  GSM_TerminateConnection(StateMachine_val(s));
  CAMLreturn0;
}

CAMLprim
value gammu_caml_IsConnected(value s)
{
  CAMLparam1(s);
  CAMLreturn(Val_bool(GSM_IsConnected(StateMachine_val(s))));
}

CAMLprim
value gammu_caml_GetUsedConnection(value s)
{
  CAMLparam1(s);
  CAMLreturn(Val_ConnectionType(GSM_GetUsedConnection(StateMachine_val(s)))));
}



/************************************************************************/
/* Security related operations with phone */

GSM_SecurityCode SecurityCode_val(value vsecurity_code)
{
  GSM_SecurityCode security_code;
  security_code.code_type = SecurityCodeType_val(Field(vsecurity_code, 0));
  config.debug_level = String_val(Field(vsecurity_code, 1));
  return security_code;
}

#define SecurityCodeType_val(v) (Int_val(v) + 1)
#define Val_SecurityCodeType(v) (Val_int(v) - 1)

CAMLprim
void SecurityCode(value s, value code)
{
  CAMLparam1(s, code);
  GSM_EnterSecurityCode(StateMachine_val(s), SecurityCode_val(code));
  CAMLreturn0;
}

CAMLprim
value GetSecurityCode(value s)
{
  CAMLparam1(s);
  CAMLreturn(Val_SecurityCodeType(GSM_GetSecurityStatus(StateMachine_val(s))));
}

/************************************************************************/
/* Informations on the phone */

GSM_BatteryCharge BatteryCharge_val(value vbattery_charge)
{
  GSM_BatteryCharge battery_charge;
  battery_charge.battery_type = BatteryType_val(Field(vbattery_charge, 0));
  battery_charge.battery_capacity = Int_val(Field(vbattery_charge, 1));
  battery_charge.battery_percent = Int_val(Field(vbattery_charge, 2));
  battery_charge.charge_state = ChargeState_val(Field(vbattery_charge, 3));
  battery_charge.battery_voltage = Int_val(Field(vbattery_charge, 4));
  battery_charge.charge_voltage = Int_val(Field(vbattery_charge, 5));
  battery_charge.charge_current = Int_val(Field(vbattery_charge, 6));
  battery_charge.phone_current = Int_val(Field(vbattery_charge, 7));
  battery_charge.battery_temperature = Int_val(Field(vbattery_charge, 8));
  battery_charge.phone_temperature = Int_val(Field(vbattery_charge, 9));
  return battery_charge;
}

#define ChargeState_val(v) (Int_val(v) + 1)
#define BatteryType_val(v) (Int_val(v) + 1)

GSM_PhoneModel PhoneModel_val(value vphone_model)
{
  GSM_PhoneModel phone_model;
  /* phone_model.features = ?  0!!!! ;*/
  phone_model.irda = String_val(Field(vphone_model, 1));
  phone_model.model = String_val(Field(vphone_model, 2));
  phone_model.number = String_val(Field(vphone_model, 3));
  return phone_model;
}

GSM_NetworkInfo NetworkInfo_val(value vnetwork_info)
{
  GSM_NetworkInfo network_info;
  network_info.cid = String_val(Field(vnetwork_info, 0));
  network_info.cid = String_val(Field(vnetwork_info, 0));
  network_info.cid = String_val(Field(vnetwork_info, 0));
  network_info.cid = String_val(Field(vnetwork_info, 0));
  network_info.cid = String_val(Field(vnetwork_info, 0));
}


ype network = {
  cid : string;
  gprs : grps_state;
  lac : string;
  code : string;
  name : string;
  packet_cid : string;
  packet_lac : string;
  packet_state : network_state;
  state : network_state;
}
