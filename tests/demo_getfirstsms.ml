(* Simple demo/test file that prints some informations and the first sms. *)
(*#use "topfind";;
  #require "gammu";;*)
open Gammu;;

let debug_level = ref "nothing";;
let connection = ref "at";;
let device = ref "/dev/ttyUSB0";;

let parse_args () =
  let args = [
    ("--debug", Arg.Set_string debug_level,
     "<debug_level>  Set debug level \
      (e.g \"textall\", defaults to \"nothing\").");
    ("--connection", Arg.Set_string connection,
     "<connection_type> Set connection/protocol type (defaults to \"at\").");
    ("--device", Arg.Set_string device,
     "<device> Set device file (defaults to \"/dev/ttyUSB0\").");
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
    let sec_status = get_security_status s in
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

let () =
  parse_args ();
  let s = make () in
  configure s;
  prepare_phone s;
  let multi_sms = SMS.get s ~folder:0 ~message_number:0 in
  let sms = multi_sms.(0) in
  print_string "==SMS==\n";
  Printf.printf "Number: %s\n" sms.SMS.number;
  Printf.printf "Date and time: %s\n"
    (DateTime.os_date_time sms.SMS.date_time);
  Printf.printf "Status : %s\n"
    (match sms.SMS.state with
      SMS.Sent -> "sent";
    | SMS.Unsent -> "unsent";
    | SMS.Read -> "read";
    | SMS.Unread -> "unread");
  print_string "Text : ";
  if (sms.SMS.udh_header.SMS.udh = SMS.No_udh) then
    (* There's no udh so text is raw in the sms message. *)
    print_string sms.SMS.text
  else begin
    (* There's an udh so we have to decode the sms. *)
    let multi_info = SMS.decode_multipart multi_sms in
    Array.iter (fun info -> print_string info.SMS.buffer) multi_info.SMS.entries
  end;
  print_newline ();
  disconnect s;;

