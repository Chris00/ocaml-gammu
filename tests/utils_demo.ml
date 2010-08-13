open Gammu

let debug_level = ref "nothing";;
let connection = ref "at";;
let device = ref "/dev/ttyUSB0";;
let folder = ref 1;;
let message_number = ref 1;;

let parse_args () =
  let args = [
    ("--debug", Arg.Set_string debug_level,
     "<debug_level>  Set debug level \
      (e.g \"textall\", defaults to \"nothing\").");
    ("--connection", Arg.Set_string connection,
     "<connection_type> Set connection/protocol type (defaults to \"at\").");
    ("--device", Arg.Set_string device,
     "<device> Set device file (defaults to \"/dev/ttyUSB0\")."); 
    ("--folder", Arg.Set_int folder,
     "<connection_type> Set folder location (default = 1).");
    ("--message-number", Arg.Set_int message_number,
     "<connection_type> Set message number (default = 1).");
  ] in
  let anon _ = raise (Arg.Bad "No anonymous arguments.") in
  Arg.parse args anon "Usage:";;

let configure s =
  (* TODO: debug things seem to be ignored... *)
  let config = {
    model = "";
    debug_level = !debug_level;
    device = !device;
    connection = !connection;
    sync_time = true;
    lock_device = false;
    debug_file = "";
    start_info = true;
    use_global_debug_file = true;
    text_reminder = "";
    text_meeting = "";
    text_call = "";
    text_birthday = "";
    text_memo = "";
  } in
  let di = get_debug s in
  Debug.set_global di true;
  Debug.set_output Debug.global stderr;
  Debug.set_level Debug.global !debug_level;
  push_config s config;
  assert (length_config s = 1);;

(* Connect and unlock phone. *)
let prepare_phone s =
  (* Unlock the phone asking user for codes. *)
  let rec ask_user_code s code_type code_type_name =
    print_string ("Enter " ^ code_type_name ^ " code : ");
    flush stdout;
    let code = read_line () in
    try
      enter_security_code s ~code_type ~code;
      (* Check if there's another security code to enter. *)
      unlock_phone s;
    with Error SECURITYERROR ->
      print_string "Wrong code, retry.\n";
      flush stdout;
      ask_user_code s code_type code_type_name;
  and unlock_phone s =
    let sec_status =
      try
        get_security_status s
      with Error UNKNOWNRESPONSE -> SEC_None
    in
    (match sec_status with
      SEC_None -> print_string "SIM/Phone unlocked.\n"
    | SEC_SecurityCode as c -> ask_user_code s c "Security"
    | SEC_Pin as c -> ask_user_code s c "PIN"
    | SEC_Pin2 as c -> ask_user_code s c "PIN2"
    | SEC_Puk as c -> ask_user_code s c "PUK"
    | SEC_Puk2 as c -> ask_user_code s c "PUK2"
    | SEC_Phone as c -> ask_user_code s c "Phone"
    | SEC_Network as c -> ask_user_code s c "Network")
  in
  print_string "Trying to connect.\n";
  flush stdout;
  connect s;
  print_string ("Phone model : " ^ Info.model s ^ "\n");
  print_string "Unlock SIM/Phone:\n";
  flush stdout;
  unlock_phone s;;
