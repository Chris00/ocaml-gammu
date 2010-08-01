(* TODO:?? Split the modules in mutiple files as C Gammu does ? *)
(** Interface to the gammu library (libGammu) to manage data in your
    cell phone such as contacts, calendar or messages.

    NOTE: Strings used by libGammu often have a maximum allowed
    length. Strings too long will be trimmed before being passed to libGammu
    (caml Strings remain immutable).

    NOTE: this library is not thread safe. *)

(************************************************************************)
(** {2 Error handling} **)

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
  | COULD_NOT_DECODE    (** Decoding SMS Message failed. *)
  | INVALID_CONFIG_NUM  (** Invalid config number. *)

val string_of_error : error -> string

exception Error of error
(** May be raised by any of the functions of this module to indicate an
    error. *)


(************************************************************************)
(** {2 Debuging handling} *)
module Debug :
sig
  type info

  val global : unit -> info
  (** @return global debug settings. *)

  val set_global : info -> bool -> unit
  (** Enables using of global debugging configuration. Makes no effect
      on global debug configuration. *)

  val set_output : info -> out_channel -> unit
  (** [set_debug_output channel di] sets output channel of [di] to
      [channel]. *)

  val set_level : info -> string -> unit
  (** [set_debug_level level di] sets debug level on [di] according to
      [level].

      [level] must be one of :
      {ul
      nothing
      text
      textall
      binary
      errors
      textdate
      textalldate
      errorsdate} *)
end


(************************************************************************)
(** {2 State machine} *)

type t
(** Value holding information about phone connection (called a "state
    machine"). *)

(** Configuration of state machine.  *)
type config = {
  model : string;
  (** Model from config file. Leave it empty for autodetection. Or define a
      phone model to force the phone model and bypass automatic phone model
      detection. *)
  debug_level : string;        (** Debug level  *)
  device : string;             (** Device name from config file such as "com2" or "/dev/ttyS1". *)
  connection : string;         (** Connection type as string  *)
  sync_time : bool;            (** Synchronize time on startup?  *)
  lock_device : bool;          (** Lock device ? (Unix, ignored on Windows) *)
  debug_file : string;         (** Name of debug file  *)
  start_info : bool;           (** Display something during start ?  *)
  use_global_debug_file : bool; (** Should we use global debug file?  *)
  text_reminder : string;      (** Text for reminder calendar entry category
                                   in local language  *)
  text_meeting : string;       (** Text for meeting calendar entry category
                                   in local language  *)
  text_call : string;          (** Text for call calendar entry category
                                   in local language  *)
  text_birthday : string;      (** Text for birthday calendar entry category
                                   in local language  *)
  text_memo : string;          (** Text for memo calendar entry
                                   category in local language *)
(* phone_features : feature list (** NYI Phone features override. *) *)
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

val get_debug : t -> Debug.info
(** Gets debug information for state machine. *)

val init_locales : ?path:string -> unit -> unit
(** Initializes locales. This sets up things needed for proper string
    conversion from local charset as well as initializes gettext based
    translation.

    @param path Path to gettext translation. If not set, compiled in
    default is used. *)

val make : unit -> t
(** Make a new clean state machine. *)

val get_config : t -> int -> config
(** [get_config s num] gets gammu configuration from state machine [s],
    where [num] is the number of the section to read, [-1] for the
    currently used one. *)

val set_config : t -> config -> int -> unit
(** [set_config s config num] sets [num]th state machine configuration [s] to
    [config]. *)

val push_config : t -> config -> unit
(** [push_config s cfg] push the configuration [cfg] on top of the
    configuration stack of [s]. *)

val remove_config : t -> config
(** [remove_config s] remove the top configuration from the config stack of
    [s]. *)

val length_config : t -> int
(** @return length of the configuration stack of the state machine. i.e
    the number of active configurations. *)

val load_gammurc : ?path:string -> t -> unit
(** (* NYI *) Automaticaly find the gammurc file (see {!Gammu.find_gammurc}),
    read it and push the configs in the state machine.

    @param path force the use of a custom path instead of the autodetected
    one (default: autodetection is performed). *)

(* maybe a type t should be created by reading a config file, then one
   connects.  config files seem to play the same role as files for
   [open_*] *)
val connect : ?log:(string -> unit) -> ?reply_num:int -> t -> unit
(** Initiates connection.

    @param log logging function.
    @param reply_num number of replies to await (default 3).

    @raise UNCONFIGURED if no configuration was set. *)

val disconnect : t -> unit

val is_connected : t -> bool

val get_used_connection : t -> connection_type

val read_device : ?wait_for_reply:bool -> t -> int
(** Attempts to read data from phone. Thus can be used for getting status
    of incoming events, which would not be found out without polling
    device.

    @return the number of read bytes. Beware if the value is 32, it could
    be that the device is not connected, error {!Gammu.NOTCONNECTED}
    (libGammu's fault).

    @param wait_for_reply whether to wait for some event (default true). *)

(************************************************************************)
(** {2 INI files} *)

(** These functions parse ini file and make them available in easily
    accessable manner. *)
module INI : sig
  (*type entry (* Useless, never used and abstract *) *)
  (* TODO:?? section is in fact a node of a doubly-linked list. Should
     this be reflected on the interface ? Along with FIXME in [read],
     store the unicode flag in the abstract [section] type or expose it to
     public interface ? *)
  type sections

  val read : ?unicode:bool -> string -> sections
  (** [read fname] reads INI data from the file [fname].

      @param unicode Whether file should be treated as unicode encoded. *)

  val ini_of_gammurc : ?path:string -> unit -> sections
  (** Finds and reads gammu configuration file.  The search order depends on
      platform.  On POSIX systems it looks for ~/.gammurc and then for
      /etc/gammurc, on Windows for gammurc in Application data folder, then in
      home and last fallback is in current directory.

      @param path force the use of a custom path instead of the autodetected
      one (default: autodetection is performed).

      @raise CANTOPENFILE if no gammu rc file can be found.

      @raise FILENOTSUPPORTED if first found gammu rc file is not valid. *)

  val config_of_ini : sections -> int -> config
  (** [read_config section num] processes and returns gammu configuration
      represented by the [num]th section of the INI file representation
      [section]. Beware that [num]th section is in facts the section named
      "gammu[num]" *)

  val get_value : sections -> section:string -> key:string -> string
(** @return value of the INI file entry. *)

end

(************************************************************************)
(** {2 Security related operations with phone. } *)

(** Definition of security codes. *)
type security_code_type =
  | SEC_SecurityCode (** Security code. *)
  | SEC_Pin     (** PIN. *)
  | SEC_Pin2    (** PIN 2. *)
  | SEC_Puk     (** PUK. *)
  | SEC_Puk2    (** PUK 2. *)
  | SEC_None    (** Code not needed. *)
  | SEC_Phone   (** Phone code needed. *)
  | SEC_Network (** Network code needed. *)

val enter_security_code : t -> code_type:security_code_type -> code:string -> unit
(** Enters security code (PIN, PUK,...). *)

val get_security_status : t -> security_code_type
(** Queries whether some security code needs to be entered. *)


(************************************************************************)
(** {2 Informations on the phone} *)

type battery_charge = {
  battery_type : battery_type; (** Battery type. *)
  battery_capacity : int;      (** Remaining battery capacity (in mAh). *)

  battery_percent : int;       (** Remaining battery capacity in
                                   percent, -1 = unknown. *)
  charge_state : charge_state; (** Charge state. *)
  battery_voltage : int;       (** Current battery voltage (in mV). *)
  charge_voltage : int;        (** Voltage from charger (in mV). *)
  charge_current : int;        (** Current from charger (in mA). *)
  phone_current : int;         (** Phone current consumption (in mA). *)
  battery_temperature : int;   (** Battery temperature
                                   (in degrees Celsius). *)
  phone_temperature : int;     (** Phone temperature (in degrees Celsius). *)
}
and charge_state =
  | BatteryPowered      (** Powered from battery *)
  | BatteryConnected    (** Powered from AC, battery connected *)
  | BatteryCharging     (** Powered from AC, battery is charging *)
  | BatteryNotConnected (** Powered from AC, no battery *)
  | BatteryFull         (** Powered from AC, battery is fully charged *)
  | PowerFault          (** Power failure  *)
and battery_type =
  | Unknown     (** Unknown battery *)
  | NiMH        (** NiMH battery *)
  | LiIon       (** Lithium Ion battery *)
  | LiPol       (** Lithium Polymer battery *)

type firmware = {
  version : string;
  ver_date : string;
  ver_num : int;
}

(** Model identification, used for finding phone features. *)
type phone_model = {
  model : string;          (** Model as returned by phone *)
  number : string;         (** Identification by Gammu *)
  irda : string;           (** Model as used over IrDA *)
  (* features : feature list; (** NYI List of supported features *)*)
}

(** Current network informations *)
type network = {
  cid : string;                 (** Cell ID (CID) *)
  code : string;                (** GSM network code *)
  state : network_state;        (** Status of network logging. *)
  lac : string;                 (** LAC (Local Area Code) *)
  name : string;                (** Name of current netwrok as returned
                                   from phone (or empty) *)
  gprs : gprs_state;            (** GRPS state *)
  packet_cid : string;          (** Cell ID (CID) for packet network *)
  packet_state : network_state; (** Status of network logging
                                   for packet data. *)
  packet_lac : string;          (** LAC (Local Area Code)
                                   for packet network *)
}
and gprs_state =
  | Detached
  | Attached
  | Unknown
and network_state =
  | HomeNetwork          (** Home network for used SIM card. *)
  | NoNetwork            (** No network available for used SIM card. *)
  | RoamingNetwork       (** SIM card uses roaming. *)
  | RegistrationDenied   (** Network registration denied
                             - card blocked or expired or disabled. *)
  | Unknown              (** Unknown network status. *)
  | RequestingNetwork    (** Network explicitely requested by user. *)

(** Information about signal quality, all these should be -1 when
    unknown. *)
type signal_quality = {
  signal_strength : int;
  signal_percent : int;  (* Signal strength in percent. *)
  bit_error_rate : int;  (* Bit error rate in percent.  *)
}

val battery_charge : t -> battery_charge
  (** @return information about battery charge and phone charging state. *)

val firmware : t -> firmware

val hardware : t -> string

val imei : t -> string
  (** @return IMEI (International Mobile Equipment Identity) / Serial Number *)

val manufacture_month : t -> string

val manufacturer : t -> string

val model : t -> string

val model_info : t -> phone_model

val network_info : t -> network

val product_code : t -> string

val signal_quality : t -> signal_quality

(************************************************************************)
(** {2 Date and time} *)

type date_time = {
  timezone : int; (* The difference between local time and GMT in seconds *)
  second : int;
  minute : int;
  hour : int;
  day : int;
  month : int;    (* January = 1, February = 2, etc. *)
  year : int;     (* Complete year number. Not 03, but 2003. *)
}

val check_date : date_time -> bool
(** Checks whether date is valid. This does not check time, see
    [check_time] for this. *)

val check_time : date_time -> bool
(** Checks whether time is valid. This does not check date, see
    [check_date] for this. *)

val os_date : date_time -> string
(** Converts date from timestamp to string according to OS settings. *)

val os_date_time : ?timezone:bool -> date_time -> string
(** Converts timestamp to string according to OS settings.

    @param timezone Whether to include time zone (default false). *)

(************************************************************************)
(** {2 Memory} *)

(** Defines ID for various phone and SIM memories.  Phone modules can
    translate them to values specific for concrete models.  Two letter
    codes (excluding VM and SL) are from GSM 07.07. *)
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

(** Value for saving phonebook entries. *)
type memory_entry = {
  memory_type : memory_type; (** Used memory for phonebook entry. *)
  location : int; (** Used location for phonebook entry. *)
  entries : sub_memory_entry array; (** Values of SubEntries. *)
} (** One value of phonebook memory entry. *)
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
} (** Type of specific phonebook entry. In parenthesis is specified in
      which member of {!sub_memory_entry} value is stored. *)
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
(** {2 Messages} *)

(** SMS messages manipulations.  *)
module SMS : sig

  type format = Pager | Fax | Email | Text
  type validity_period = Hour_1 | Hour_6 | Day_1 | Day_3 | Week | Max_time

  type state = Sent | Unsent | Read | Unread

  type udh =
    | No_udh
    | ConcatenatedMessages      (** Linked SMS. *)
    | ConcatenatedMessages16bit (** Linked SMS with 16 bit reference. *)
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
    udh : udh;          (** UDH type. *)
    text : string;      (** UDH text. *)
    id8bit : int;       (** 8-bit ID, when required (-1 otherwise). *)
    id16bit : int;      (** 16-bit ID, when required (-1 otherwise). *)
    part_number : int;  (** Number of current part. *)
    all_parts : int;    (** Total number of parts. *)
  }

  type message_type =
    | Deliver           (** SMS in Inbox. *)
    | Status_Report     (** Delivery Report *)
    | Submit            (** SMS for sending or in Outbox  *)

  type coding =
    | Unicode_No_Compression     (** Unicode *)
    | Unicode_Compression
    | Default_No_Compression     (** Default GSM alphabet. *)
    | Default_Compression
    | Eight_bit                  (** 8-bit.  *)

  type message = {
    replace_message : char;
    reject_duplicates : bool;
    udh : udh_header;
    number : string;
    other_numbers : string array;
    (* smsc : smsc;     (** NYI SMS Center *) *)
    memory : memory_type; (** For saved SMS: where exactly
                              it's saved (SIM/phone). *)
    location : int;  (** For saved SMS: location of SMS in memory. *)
    folder : int;    (** For saved SMS: number of folder,
                         where SMS is saved. *)
    inbox_folder : bool; (** For saved SMS: whether SMS is really in Inbox. *)
    state : state;   (** Status (read/unread/...) of SMS message. *)
    name : string;   (** Name in Nokia with SMS memory (6210/7110, etc.)
                         Ignored in other. *)
    text : string;   (** Text for SMS. *)
    pdu : message_type; (** Type of message. *)
    coding : coding; (** Type of coding. *)
    date_time : date_time;
    smsc_time : date_time;
    delivery_status : char; (** In delivery reports: status. *)
    reply_via_same_smsc : bool; (** Indicates whether "Reply via same
                                    center" is set. *)
    sms_class : char; (** SMS class (0 is flash SMS, 1 is normal one). *)
    message_reference : char; (** Message reference. *)
  }

  type multi_sms = message array
  (** Multiple SMS messages, used for Smart Messaging 3.0/EMS. *)

  val get : t -> folder:int -> message_number:int -> multi_sms
  (** Reads SMS message. *)

  val get_next : t -> folder:int -> ?message_number:int -> unit -> multi_sms
  (** Reads next SMS message (iterating trough SMS's *and* folders). This
      might be faster for some phones than using {!Gammu.SMS.get} for each
      message.

      Please note that this command does not mark the message as read in
      phone. To do so, you have to call {!Gammu.SMS.get}.

      @param message_number if no defined, start reading from beginning.

      @raise EMPTY if there's no next SMS.

      @raise NOTIMPLEMENTED if GetNext function is not implemented in libGammu
      for the the currently used phone.*)

  type folder_box = Inbox | Outbox

  type folder = {
    box : folder_box;     (** Whether it is inbox or outbox. *)
    memory : memory_type; (** Where exactly it's saved. *)
    name : string;        (** Name of the folder. *)
  }

  (* val folders : t -> folder array (* NYI *) *)
  (** @return SMS folders information. *)

  (** Status of SMS memory. *)
  type memory_status = {
    sim_unread : int;     (** Number of unread messages on SIM. *)
    sim_used : int;       (** Number of saved messages
                             (including unread) on SIM. *)
    sim_size : int;       (** Number of possible messages on SIM. *)
    templates_used : int; (** Number of used templates (62xx/63xx/7110/etc.). *)
    phone_unread : int;   (** Number of unread messages in phone. *)
    phone_used : int;     (** Number of saved messages in phone. *)
    phone_size : int;     (** Number of possible messages on phone. *)
  }

  val get_status : t -> memory_status
  (** Get information about SMS memory
      (read/unread/size of memory for both SIM and
      phone). *)

  val set_incoming_sms : t -> bool -> unit
  (** Enable/disable notification on incoming SMS. *)

  val delete : t -> folder:int -> message_number:int -> unit
  (** Deletes SMS (SMS location and folder must be set). *)

  (** Multipart SMS Information *)
  type multipart_info = {
    unicode_coding : bool;
    info_class : int;
    replace_message : char;
    unknown : bool;
    entries : info array;
  } (** SMS information, like type, text, text properties, etc... *)
  and info = {
    id : part_type_id;
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
  } (** ID during packing SMS for Smart Messaging 3.0, EMS and other *)
  and part_type_id =
    | Text (** 1 text SMS. *)
    | ConcatenatedTextLong (** Contacenated SMS, when longer than 1 SMS. *)
    | ConcatenatedAutoTextLong (** Contacenated SMS, auto Default/Unicode
                                   coding. *)
    | ConcatenatedTextLong16bit
    | ConcatenatedAutoTextLong16bit
    | NokiaProfileLong (** Nokia profile = Name, Ringtone, ScreenSaver *)
    | NokiaPictureImageLong (** Nokia Picture Image + (text) *)
    | NokiaScreenSaverLong (** Nokia screen saver + (text) *)
    | NokiaRingtone (** Nokia ringtone - old SM2.0 format, 1 SMS *)
    | NokiaRingtoneLong (** Nokia ringtone contacenated, when very long *)
    | NokiaOperatorLogo (** Nokia 72x14 operator logo, 1 SMS *)
    | NokiaOperatorLogoLong (** Nokia 72x14 op logo or 78x21 in 2 SMS *)
    | NokiaCallerLogo (** Nokia 72x14 caller logo, 1 SMS *)
    | NokiaWAPBookmarkLong (** Nokia WAP bookmark in 1 or 2 SMS *)
    | NokiaWAPSettingsLong (** Nokia WAP settings in 2 SMS *)
    | NokiaMMSSettingsLong (** Nokia MMS settings in 2 SMS *)
    | NokiaVCARD10Long (** Nokia VCARD 1.0 - only name and default
                           number *)
    | NokiaVCARD21Long (** Nokia VCARD 2.1 - all numbers + text *)
    | NokiaVCALENDAR10Long (** Nokia VCALENDAR 1.0 - can be in few sms *)
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
    | EMSSound10 (** IMelody 1.0 *)
    | EMSSound12 (** IMelody 1.2 *)
    | EMSSonyEricssonSound (** IMelody without header
                               - SonyEricsson extension *)
    | EMSSound10Long (** IMelody 1.0 with UPI. *)
    | EMSSound12Long (** IMelody 1.2 with UPI. *)
    | EMSSonyEricssonSoundLong (** IMelody without header with UPI. *)
    | EMSPredefinedSound
    | EMSPredefinedAnimation
    | EMSAnimation
    | EMSFixedBitmap (** Fixed bitmap of size 16x16 or 32x32. *)
    | EMSVariableBitmap
    | EMSVariableBitmapLong
    | MMSIndicatorLong (** MMS message indicator. *)
    | WAPIndicatorLong
    | AlcatelMonoBitmapLong (** Variable bitmap with black and white
                                colors *)
    | AlcatelMonoAnimationLong (** Variable animation with black and white
                                   colors *)
    | AlcatelSMSTemplateName
    | SiemensFile (** Siemens OTA  *)

  val decode_multipart : ?debug:Debug.info -> ?ems:bool ->
    multi_sms -> multipart_info
(** [decode_multipart sms] Decodes multi part SMS to "readable"
    format. [sms] is modified, return a {!Gammu.multipart_info}
    associated.

    @param di log according to debug settings from [di]. If not specified,
    use the one returned by {!Gammu.get_global_debug}.

    @param ems whether to use EMS (Enhanced Messaging Service)
    (default true). *)

end

(************************************************************************)
(* Events *)

val incoming_sms : t -> (SMS.message -> unit) -> unit
(** [incoming_sms s f] register [f] as callback function in the event of an
    incoming SMS. *)

val disable_incoming_sms : t -> unit
