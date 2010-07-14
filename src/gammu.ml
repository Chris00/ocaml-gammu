(* File: gammu.ml

   Copyright (C) 2010

     Christophe Troestler <Christophe.Troestler@umons.ac.be>
     Noémie Meunier <Noemie.Meunier@student.umons.ac.be>
     Pierre Hauweele <Pierre.Hauweele@student.umons.ac.be>

     WWW: http://math.umons.ac.be/an/software/

   This library is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License version 3 or
   later as published by the Free Software Foundation.

   This library is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the file
   LICENSE for more details. *)

(* Register OCAML callbacks for use in C stubs. *)
let _ =
  Callback.register "Char.code" Char.code;
  Callback.register "Char.chr" Char.chr;;

(************************************************************************)
(* Error handling *)

type error =
  | NONE                (** No error *)
  | DEVICEOPENERROR     (** Error during opening device *)
  | DEVICELOCKED        (** Device locked *)
  | DEVICENOTEXIST      (** Device does not exits *)
  | DEVICEBUSY          (** Device is busy *)
  | DEVICENOPERMISSION  (** No permissions to open device *)
  | DEVICENODRIVER      (** No driver installed for a device *)
  | DEVICENOTWORK       (** Device doesn't seem to be working *)
  | DEVICEDTRRTSERROR   (** Error during setting DTR/RTS in device *)
  | DEVICECHANGESPEEDERROR (** Error during changing speed in device *)
  | DEVICEWRITEERROR    (** Error during writing device *)
  | DEVICEREADERROR     (** Error during reading device *)
  | DEVICEPARITYERROR   (** Can't set parity on device *)
  | TIMEOUT             (** Command timed out *)
  | FRAMENOTREQUESTED   (** Frame handled, but not requested in this moment *)
  | UNKNOWNRESPONSE     (** Response not handled by gammu *)
  | UNKNOWNFRAME        (** Frame not handled by gammu *)
  | UNKNOWNCONNECTIONTYPESTRING (** Unknown connection type given by user *)
  | UNKNOWNMODELSTRING  (** Unknown model given by user *)
  | SOURCENOTAVAILABLE  (** Some functions not compiled in your OS *)
  | NOTSUPPORTED        (** Not supported by phone *)
  | EMPTY               (** Empty entry or transfer end. *)
  | SECURITYERROR       (** Not allowed *)
  | INVALIDLOCATION     (** Too high or too low location... *)
  | NOTIMPLEMENTED      (** Function not implemented *)
  | FULL                (** Memory is full *)
  | UNKNOWN             (** Unknown response from phone *)
  | CANTOPENFILE        (** Error during opening file *)
  | MOREMEMORY          (** More memory required *)
  | PERMISSION          (** No permission *)
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
  | OTHERCONNECTIONREQUIRED (** You need other connection for
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
  | GNAPPLETWRONG       (** Invalid gnapplet version *)
  | FOLDERPART          (** Only part of folders listed *)
  | FOLDERNOTEMPTY      (** Folder is not empty *)
  | DATACONVERTED       (** Data were converted *)
  | UNCONFIGURED        (** Gammu is not configured. *)
  | WRONGFOLDER         (** Wrong folder selected (eg. for SMS). *)
  | PHONE_INTERNAL      (** Internal phone error (phone got crazy). *)
  | WRITING_FILE        (** Could not write to a file (on local filesystem). *)
  | NONE_SECTION        (** No such section exists. *)
  | USING_DEFAULTS      (** Using default values. *)
  | CORRUPTED           (** Corrupted data returned by phone. *)
  | BADFEATURE          (** Bad feature string. *)
  | DISABLED            (** Some functions not compiled in your OS *)
  | SPECIFYCHANNEL      (** Bluetooth configuration requires channel option. *)
  | NOTRUNNING          (** Service is not runnig. *)
  | NOSERVICE           (** Service setup is missing. *)
  | BUSY                (** Command failed. Try again. *)
  | COULDNT_CONNECT     (** Can not connect to server. *)
  | COULDNT_RESOLVE     (** Can not resolve host name. *)
  (* Caml bindings own errors *)
  | INI_KEY_NOT_FOUND   (** Pair section/value not found in INI file. *)

exception Error of error

let () = Callback.register_exception "Gammu.Error" (Error NONE);

(************************************************************************)
(* Debuging handling *)

type debug_info

external string_of_error : error -> string = "gammu_caml_ErrorString"

external get_global_debug : unit -> debug_info = "gammu_caml_GetGlobalDebug"

external set_debug_global : bool -> debug_info -> unit
  = "gammu_caml_SetDebugGlobal"

external set_debug_output : out_channel -> debug_info -> unit
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

  external _read : string -> bool -> section_node = "gammu_caml_INI_ReadFile"
  let read ?(unicode=true) file_name =
    { head = _read file_name unicode;
      unicode = unicode; }

  external _get_value : section_node -> string -> string -> bool -> string
    = "gammu_caml_INI_GetValue"
  let get_value file_info ~section ~key =
    _get_value file_info.head section key file_info.unicode

  (*let find_last_entry file_info ~section =
    _find_last_entry file_info.head file_info.unicode ~section
  external _find_last_entry : sections -> string -> bool -> entry
    = "gammu_caml_FindLastEntry" *)

end

(************************************************************************)
(* State machine *)

(* Abstract type wrapping to expose abstracted dependencies to the GC. *)
type state_machine
type t = {
  s : state_machine;
  di : debug_info;
(* Others ? *)
}

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

external _init_locales : string -> unit = "gammu_caml_InitLocales"
external _init_default_locales : unit -> unit = "gammu_caml_InitDefaultLocales"
let init_locales ?path () = match path with
  | None -> _init_default_locales ()
  | Some path -> _init_locales path

external make : unit -> t = "gammu_caml_CreateStateMachine"

external _find_gammurc_force : string -> INI.section_node
  = "gammu_caml_FindGammuRC_force"
external _find_gammurc : unit -> INI.section_node = "gammu_caml_FindGammuRC"
let find_gammurc ?path () =
  let s_node = match path with
    | None -> _find_gammurc ()
    | Some path -> _find_gammurc_force path
  in
  { INI.head = s_node;  unicode=false; }

external _read_config : INI.section_node -> int -> config =
  "gammu_caml_ReadConfig"

let read_config cfg_info num =
  _read_config cfg_info.INI.head num

external get_config : t -> int -> config = "gammu_caml_GetConfig"

external set_config : t -> config -> int -> unit = "gammu_caml_SetConfig"

external push_config : t -> config -> unit = "gammu_caml_PushConfig"

external remove_config : t -> config = "gammu_caml_RemoveConfig"

external length_config : t -> int = "gammu_caml_GetConfigNum"

external _connect : t -> int -> unit= "gammu_caml_InitConnection"
external _connect_log : t -> int -> (string -> unit) -> unit
  = "gammu_caml_InitConnection_Log"

let connect ?log ?(reply_num=3) s = match log with
  | None -> _connect s reply_num
  | Some log_func -> _connect_log s reply_num log_func

external disconnect : t -> unit = "gammu_caml_TerminateConnection"

external is_connected : t -> bool = "gammu_caml_IsConnected"

external get_used_connection : t -> connection_type =
  "gammu_caml_GetUsedConnection"

external _read_device : t -> bool -> int = "gammu_caml_ReadDevice"
let read_device ?(wait_for_reply=true) s =
  _read_device s wait_for_reply

(************************************************************************)
(* Security related operations with phone *)

type security_code_type =
  | SEC_SecurityCode
  | SEC_Pin
  | SEC_Pin2
  | SEC_Puk
  | SEC_Puk2
  | SEC_None
  | SEC_Phone
  | SEC_Network

type security_code = {
  code_type : security_code_type;
  code : string;
}

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
  model : string;
  number : string;
  irda : string;
  (* features : feature list; *)
}

type network = {
  cid : string;
  code : string;
  state : network_state;
  lac : string;
  name : string;
  gprs : gprs_state;
  packet_cid : string;
  packet_state : network_state;
  packet_lac : string;
}
and gprs_state =
  | Detached
  | Attached
  | Unknown
and network_state =
  | HomeNetwork
  | NoNetwork
  | RoamingNetwork
  | RegistrationDenied
  | Unknown
  | RequestingNetwork

type signal_quality = {
  signal_strength : int;
  signal_percent : int;
  bit_error_rate : int;
}

external battery_charge : t -> battery_charge = "gammu_caml_GetBatteryCharge"

external firmware : t -> firmware = "gammu_caml_GetFirmWare"

external hardware : t -> string = "gammu_caml_GetHardware"

external imei : t -> string = "gammu_caml_GetIMEI"

external manufacture_month : t -> string = "gammu_caml_GetManufactureMonth"

external manufacturer : t -> string = "gammu_caml_GetManufacturer"

external model : t -> string = "gammu_caml_GetModel"

external model_info : t -> phone_model = "gammu_caml_GetModelInfo"

external network_info : t -> network = "gammu_caml_GetNetworkInfo"

external product_code : t -> string = "gammu_caml_GetProductCode"

external signal_quality : t -> signal_quality = "gammu_caml_GetSignalQuality"


(************************************************************************)
(* Date and time *)

type date_time = {
  timezone : int;
  second : int;
  minute : int;
  hour : int;
  day : int;
  month : int;
  year : int;
}

external check_date : date_time -> bool = "gammu_caml_CheckDate"

external check_time : date_time -> bool = "gammu_caml_CheckTime"

external os_date : date_time -> string = "gammu_caml_OSDate"

external _os_date_time : date_time -> bool -> string = "gammu_caml_OSDateTime"

let os_date_time ?(timezone=false) dt =
  _os_date_time dt timezone

(************************************************************************)
(* Memory *)

type memory_type =
  | ME (** Internal memory of the mobile equipment *)
  | SM (** SIM card memory *)
  | ON (** Own numbers *)
  | DC (** Dialled calls *)
  | RC (** Received calls *)
  | MC (** Missed calls *)
  | MT (** Combined ME and SIM phonebook *)
  | FD (** Fixed dial *)
  | VM (** Voice mailbox *)
  | SL (** Sent SMS logs *)
  | QD (** Quick dialing choices *)

type memory_entry = {
  memory_type : memory_type; (** Used memory for phonebook entry. *)
  location : int; (** Used location for phonebook entry. *)
  entries : sub_memory_entry array; (** Values of SubEntries. *)
}
and sub_memory_entry = {
  entry_type : entry_type; (** Type of entry. *)
  date : date_time; (** Text of entry (if applicable, see {!entry_type}). *)
  number : int; (** Number of entry (if applicable, see {!entry_type}). *)
  voice_tag : int; (** Voice dialling tag. *)
  sms_list : int array;
  call_length : int;
  add_error : error; (** During adding SubEntry Gammu can return here info,
                         if it was done OK. *)
  text : string; (** Text of entry (if applicable, see GSM_EntryType). *)
  (* picture : binary_picture (* NYI Picture data. *) *)
}
and entry_type =
  | Number_General (** General number. (Text) *)
  | Number_Mobile (** Mobile number. (Text) *)
  | Number_Work (** Work number. (Text) *)
  | Number_Fax (** Fax number. (Text) *)
  | Number_Home (** Home number. (Text) *)
  | Number_Pager (** Pager number. (Text) *)
  | Number_Other (** Other number. (Text) *)
  | Text_Note (** Note. (Text) *)
  | Text_Postal (** Complete postal address. (Text) *)
  | Text_Email (** Email. (Text) *)
  | Text_Email2
  | Text_URL (** URL (Text) *)
  | Date (** Date and time of last call. (Date) *)
  | Caller_Group (** Caller group. (Number) *)
  | Text_Name (** Name (Text) *)
  | Text_LastName (** Last name. (Text) *)
  | Text_FirstName (** First name. (Text) *)
  | Text_Company (** Company. (Text) *)
  | Text_JobTitle (** Job title. (Text) *)
  | Category (** Category. (Number, if -1 then text) *)
  | Private (** Whether entry is private. (Number) *)
  | Text_StreetAddress (** Street address. (Text) *)
  | Text_City (** City. (Text) *)
  | Text_State (** State. (Text) *)
  | Text_Zip (** Zip code. (Text) *)
  | Text_Country (** Country. (Text) *)
  | Text_Custom1 (** Custom information 1. (Text) *)
  | Text_Custom2 (** Custom information 2. (Text) *)
  | Text_Custom3 (** Custom information 3. (Text) *)
  | Text_Custom4 (** Custom information 4. (Text) *)
  | RingtoneID (** Ringtone ID. (Number) *)
  | PictureID (** Picture ID. (Number) *)
  | Text_UserID (** User ID. (Text) *)
  | CallLength (** Length of call (Number) *)
  | Text_LUID (** LUID - Unique Identifier used for synchronisation (Text) *)
  | LastModified (** Date of last modification (Date) *)
  | Text_NickName (** Nick name (Text) *)
  | Text_FormalName (** Formal name (Text) *)
  | Text_WorkStreetAddress (** Work street address. (Text) *)
  | Text_WorkCity (** Work city. (Text) *)
  | Text_WorkState (** Work state. (Text) *)
  | Text_WorkZip (** Work zip code. (Text) *)
  | Text_WorkCountry (** Work country. (Text) *)
  | Text_WorkPostal (** Complete work postal address. (Text) *)
  | Text_PictureName (** Picture name (on phone filesystem). (Text) *)
  | PushToTalkID (** Push-to-talk ID (Text) *)
  | Number_Messaging (** Favorite messaging number. (Text) *)
  | Photo (** Photo (Picture). *)
  | Number_Mobile_Home (** Home mobile number. (Text) *)
  | Number_Mobile_Work (** Work mobile number. (Text) *)

(************************************************************************)
(* Messages *)

module SMS =
struct

  type format = Pager | Fax | Email | Text

  type validity_period = Hour_1 | Hour_6 | Day_1 | Day_3 | Week | Max_time

  type state = Sent | Unsent | Read | Unread

  type udh =
    | No_udh
    | ConcatenatedMessages
    | ConcatenatedMessages16bit
    | DisableVoice
    | DisableFax
    | DisableEmail
    | EnableVoice
    | EnableFax
    | EnableEmail
    | VoidSMS
    | NokiaRingtone
    | NokiaRingtoneLong
    | NokiaOperatorLogo
    | NokiaOperatorLogoLong
    | NokiaCallerLogo
    | NokiaWAP
    | NokiaWAPLong
    | NokiaCalendarLong
    | NokiaProfileLong
    | NokiaPhonebookLong
    | UserUDH
    | MMSIndicatorLong
  and udh_header = {
    udh : udh;
    text : string;
    id8bit : int;
    id16bit : int;
    part_number : int;
    all_parts : int;
  }

  type message_type =
    | Deliver
    | Status_Report
    | Submit

  type coding =
    | Unicode_No_Compression
    | Unicode_Compression
    | Default_No_Compression
    | Default_Compression
    | Eight_bit

  type message = {
    replace_message : char;
    reject_duplicates : bool;
    udh : udh_header;
    number : string;
    other_numbers : string array;
    (* smsc : smsc; (* NYI *) *)
    memory : memory_type;
    location : int;
    folder : int;
    inbox_folder : bool;
    state : state;
    name : string;
    text : string;
    pdu : message_type;
    coding : coding;
    date_time : date_time;
    smsc_time : date_time;
    delivery_status : char;
    reply_via_same_smsc : bool;
    sms_class : char;
    message_reference : char;
  }

  type multipart_message = message array

  (* val get : t -> location:int -> folder:int -> multipart_message =
    "gammu_caml_GetSMS"

     val get_next : ?start:bool -> location:int -> folder:int -> t ->
     multipart_message ="gammu_caml_GetNextSMS" *)

  type folder = {
    inbox_folder : bool;
    outbox_folder : bool;
    memory : memory_type;
    name : string;
  }

  (* TODO: folders *)

  type memory_status = {
    sim_unread : int;
    sim_used : int;
    sim_size : int;
    templates_used : int;
    phone_unread : int;
    phone_used : int;
    phone_size : int;
  }

  external get_status :t -> memory_status = "gammu_caml_GetSMSStatus"

  external set_incoming_sms : t -> bool -> unit = "gammu_caml_SetIncomingSMS"

  external delete : t -> message -> unit = "gammu_caml_DeleteSMS"

  type multipart_info = {
    unicode_coding : bool;
    info_class : int;
    replace_message : char;
    unknown : bool;
    entries : entry array;
  }
  and entry = {
    id : encode_multipart_sms_id;
    number : int;
    (* ringtone : ringtone; (* NYI *)
       bitmap : multi_bitmap; (* NYI *)
       bookmark : wap_bookmark; (* NYI *)
       settings : wap_settings; (* NYI *)
       mms_indicator : mms_indicator; (* NYI *) *)
    phonebook : memory_entry;
    (* calendar : calendar_entry; (* NYI *)
       todo : todo_entry; (* NYI *)
       file : file; (* NYI *) *)
    protected : bool;
    buffer : string;
    (* TODO:?? use a variant type for alignment ? *)
    left : bool;
    right : bool;
    center : bool;
    large : bool;
    small : bool;
    bold : bool;
    italic : bool;
    underlined : bool;
    strikethrough : bool;
    ringtone_notes : int;
  }
  and encode_multipart_sms_id =
    | Text
    | ConcatenatedTextLong
    | ConcatenatedAutoTextLong
    | ConcatenatedTextLong16bit
    | ConcatenatedAutoTextLong16bit
    | NokiaProfileLong
    | NokiaPictureImageLong
    | NokiaScreenSaverLong
    | NokiaRingtone
    | NokiaRingtoneLong
    | NokiaOperatorLogo
    | NokiaOperatorLogoLong
    | NokiaCallerLogo
    | NokiaWAPBookmarkLong
    | NokiaWAPSettingsLong
    | NokiaMMSSettingsLong
    | NokiaVCARD10Long
    | NokiaVCARD21Long
    | NokiaVCALENDAR10Long
    | NokiaVTODOLong
    | VCARD10Long
    | VCARD21Long
    | DisableVoice
    | DisableFax
    | DisableEmail
    | EnableVoice
    | EnableFax
    | EnableEmail
    | VoidSMS
    | EMSSound10
    | EMSSound12
    | EMSSonyEricssonSound
    | EMSSound10Long
    | EMSSound12Long
    | EMSSonyEricssonSoundLong
    | EMSPredefinedSound
    | EMSPredefinedAnimation
    | EMSAnimation
    | EMSFixedBitmap
    | EMSVariableBitmap
    | EMSVariableBitmapLong
    | MMSIndicatorLong
    | WAPIndicatorLong
    | AlcatelMonoBitmapLong
    | AlcatelMonoAnimationLong
    | AlcatelSMSTemplateName
    | SiemensFile

  external _decode_multipart :
    debug_info ->  multipart_message -> bool -> multipart_info
      = "gammu_caml_DecodeMultiPartSMS"

  let decode_multipart ?di ?(ems=false) multp_mess =
    let di = match di with
      | None -> get_global_debug ()
      | Some s_di -> s_di
    in
    _decode_multipart di multp_mess ems

end

(************************************************************************)
(* Events *)

external incoming_sms : t -> (SMS.message -> unit) -> unit
  = "gammu_caml_SetIncomingSMS"
