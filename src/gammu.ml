(* File: gammu.ml

   Copyright (C) 2010

     Christophe Troestler <Christophe.Troestler@umons.ac.be>
     Pierre Hauweele <Pierre.Hauweele@student.umons.ac.be>
     No�mie Meunier <Noemie.Meunier@student.umons.ac.be>
     WWW: http://math.umons.ac.be/an/software/

   This library is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License version 3 or
   later as published by the Free Software Foundation.

   This library is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the file
   LICENSE for more details. *)

type error =
  | DEVICEOPENERROR     (** Error during opening device *)
  | DEVICELOCKED        (** Device locked *)
  | DEVICENOTEXIST      (** Device does not exits *)
  | DEVICEBUSY          (** Device is busy *)
  | DEVICENOPERMISSION  (** No permissions to open device *)
  | DEVICENODRIVER      (** No driver installed for a device *)
  | DEVICENOTWORK       (** Device doesn't seem to be working *)
  | DEVICEDTRRTSERROR   (** Error during setting DTR/RTS in device *)
  | DEVICECHANGESPEEDERROR (** 10 Error during changing speed in device *)
  | DEVICEWRITEERROR    (** Error during writing device *)
  | DEVICEREADERROR     (** Error during reading device *)
  | DEVICEPARITYERROR   (** Can't set parity on device *)
  | TIMEOUT             (** Command timed out *)
  | FRAMENOTREQUESTED   (** Frame handled, but not requested in this moment *)
  | UNKNOWNRESPONSE     (** Response not handled by gammu *)
  | UNKNOWNFRAME        (** Frame not handled by gammu *)
  | UNKNOWNCONNECTIONTYPESTRING (** Unknown connection type given by user *)
  | UNKNOWNMODELSTRING  (** Unknown model given by user *)
  | SOURCENOTAVAILABLE  (** 20 Some functions not compiled in your OS *)
  | NOTSUPPORTED        (** Not supported by phone *)
  | EMPTY               (** Empty entry or transfer end. *)
  | SECURITYERROR       (** Not allowed *)
  | INVALIDLOCATION     (** Too high or too low location... *)
  | NOTIMPLEMENTED      (** Function not implemented *)
  | FULL                (** Memory is full *)
  | UNKNOWN             (** Unknown response from phone *)
  | CANTOPENFILE        (** Error during opening file *)
  | MOREMEMORY          (** More memory required *)
  | PERMISSION          (** 30 No permission *)
  | EMPTYSMSC           (** SMSC number is empty *)
  | INSIDEPHONEMENU     (** Inside phone menu - can't make something *)
  | NOTCONNECTED        (** Phone NOT connected - can't make something *)
  | WORKINPROGRESS      (** Work in progress *)
  | PHONEOFF            (** Phone is disabled and connected to charger *)
  | FILENOTSUPPORTED    (** File format not supported by Gammu *)
  | BUG                 (** Found bug in implementation or phone *)
  | CANCELED            (** Action was canceled by user *)
  | NEEDANOTHERANSWER   (** Inside Gammu: phone module need to send
                            another answer frame *)
  | OTHERCONNECTIONREQUIRED (** 40 You need other connection for
                                this operation. *)
  | WRONGCRC            (** Wrong CRC *)
  | INVALIDDATETIME     (** Invalid date/time *)
  | MEMORY              (** Phone memory error, maybe it is read only *)
  | INVALIDDATA         (** Invalid data given to phone *)
  | FILEALREADYEXIST    (** File with specified name already exist *)
  | FILENOTEXIST        (** File with specified name doesn't exist *)
  | SHOULDBEFOLDER      (** You have to give folder (not file) name *)
  | SHOULDBEFILE        (** You have to give file (not folder) name *)
  | NOSIM               (** Can not access SIM card *)
  | GNAPPLETWRONG       (** 50 Invalid gnapplet version *)
  | FOLDERPART          (** Only part of folders listed *)
  | FOLDERNOTEMPTY      (** Folder is not empty *)
  | DATACONVERTED       (** Data were converted *)
  | UNCONFIGURED        (** Gammu is not configured. *)
  | WRONGFOLDER         (** Wrong folder selected (eg. for SMS). *)
  | PHONE_INTERNAL      (** Internal phone error (phone got crazy). *)
  | WRITING_FILE        (** Could not write to a file (on local filesystem). *)
  | NONE_SECTION        (** No such section exists. *)
  | USING_DEFAULTS      (** Using default values. *)
  | CORRUPTED           (** 60 Corrupted data returned by phone. *)
  | BADFEATURE          (** Bad feature string. *)
  | DISABLED            (** Some functions not compiled in your OS *)
  | SPECIFYCHANNEL      (** Bluetooth configuration requires channel option. *)
  | NOTRUNNING          (** Service is not runnig. *)
  | NOSERVICE           (** Service setup is missing. *)
  | BUSY                (** Command failed. Try again. *)
  | COULDNT_CONNECT     (** Can not connect to server. *)
  | COULDNT_RESOLVE     (** Can not resolve host name. *)

exception Error of error

(************************************************************************)
(* Debuging handling *)

type debug_info

external string_of_error : error -> string = "gammu_caml_ErrorString"

external get_global_debug : unit -> debug_info = "gammu_caml_GetGlobalDebug"

external set_debug_global : bool -> debug_info -> unit
  = "gammu_caml_SetDebugGlobal"

external set_debug_file_descr : Unix.file_descr -> bool -> debug_info -> unit
  = "gammu_caml_SetDebugFileDescriptor"

external set_debug_level : string -> debug_info -> unit
  = "gammu_caml_SetDebugLevel"

(************************************************************************)
(* INI files *)

module INI =
struct
  type entry
  type section_node
  type sections = {
    head : section_node;
    unicode : bool;
  }

  let read ?(unicode=true) file_name =
    { head = _read file_name unicode;
      unicode = unicode; }
  external _read : string -> bool -> section_node = "gammu_caml_ReadFile"

  val get_value : sections -> section:string -> key:string -> string

  (*let find_last_entry file_info ~section =
    _find_last_entry file_info.head file_info.unicode ~section
  external _find_last_entry : sections -> string -> bool -> entry
    = "gammu_caml_FindLastEntry" *)

end

(************************************************************************)
(* State machine *)

type t

type config = {
  model : string;
  debug_level : string;
  device : string;
  connection : string;
  sync_time : bool;
  lock_device : bool;
  debug_file : string;
  start_info : bool;
  use_global_debug_file : bool;
  text_reminder : string;
  text_meeting : string;
  text_call : string;
  text_birthday : string;
  text_memo : string;
}

type connection_type =
  | BUS2
  | FBUS2
  | FBUS2DLR3
  | DKU2AT
  | DKU2PHONET
  | DKU5FBUS2
  | ARK3116FBUS2
  | FBUS2PL2303
  | FBUS2BLUE
  | FBUS2IRDA
  | PHONETBLUE
  | AT
  | BLUEGNAPBUS
  | IRDAOBEX
  | IRDAGNAPBUS
  | IRDAAT
  | IRDAPHONET
  | BLUEFBUS2
  | BLUEAT
  | BLUEPHONET
  | BLUEOBEX
  | FBUS2USB
  | NONE

external get_debug : t -> debug_info = "gammu_caml_GetDebug"

let init_locales ?path () = match path with
  | None -> _init_default_locales ()
  | Some path -> _init_locales path
external _init_locales : path -> unit = "gammu_caml_InitLocales"
external _init_default_locales : unit = "gammu_caml_InitDefaultLocales"

external make : unit -> t = "gammu_caml_CreateStateMachine"

let find_gammurc ?path () = match path with
  | None -> _find_default_gammurc ()
  | Some path -> _find_gammurc path
external _find_gammurc : path -> unit = "gammu_caml_FindGammuRC"
external _find_default_gammurc : unit = "gammu_caml_FindDefaultGammuRC"

let read_config cfg_info num =
  _read_config cfg_info.INI.head num

external _read_config : INI.section_node -> int -> config =
  "gammu_caml_ReadConfig"

external get_config : t -> int -> config = "gammu_caml_GetConfig"


external disconnect : t -> unit = "gammu_caml_TerminateConnection"

external is_connected : t -> bool = "gammu_caml_IsConnected"

external get_used_connection : t -> connection_type =
  "gammu_caml_GetUsedConnection"


(************************************************************************)
(* Security related operations with phone *)

val security_code = {
  code_type : security_code_type;
  code : string;
}

val security_code_type =
  | SEC_SecurityCode
  | SEC_Pin
  | SEC_Pin2
  | SEC_Puk
  | SEC_Puk2
  | SEC_None
  | SEC_Phone
  | SEC_Network

external enter_security_code : t -> security_code -> unit =
  "gammu_caml_EnterSecurityCode"

external get_security_status : t -> security_code_type =
  "gammu_caml_GetSecurityStatus"


(************************************************************************)
(* Informations on the phone *)

type battery_charge = {
  battery_type : battery_type;
  battery_capacity : int;
  battery_percent : int;
  charge_state : charge_state;
  battery_voltage : int;
  charge_voltage : int;
  charge_current : int;
  phone_current : int;
  battery_temperature : int;
  phone_temperature : int;
}
and charge_state =
  | BatteryPowered
  | BatteryConnected
  | BatteryCharging
  | BatteryNotConnected
  | BatteryFull
  | PowerFault
and battery_type =
  | Unknown
  | NiMH
  | LiIon
  | LiPol

type firmware = {
  version : string;
  ver_date : string;
  ver_num : int;
}

type phone_model = {
  (* features : feature list;*)
  irda : string;
  model : string;
  number : string;
}

type network = {
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
and gprs_state =
  | Detached
  | Attached
and network_state =
  | HomeNetwork
  | NoNetwork
  | RoamingNetwork
  | RegistrationDenied
  | Unknown
  | RequestingNetwork
