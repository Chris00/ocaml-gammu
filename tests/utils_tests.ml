open Printf
module G = Gammu
module SMS = G.SMS

let string_of_sms_status =
  function
  | SMS.Sent -> "Sent"
  | SMS.Unsent -> "Unsent"
  | SMS.Read -> "Read"
  | SMS.Unread -> "Unread"

let print_multi_sms multi_sms =
  let sms = multi_sms.(0) in
  print_string "=== SMS ===\n";
  printf "Folder: %d\n" sms.SMS.folder;
  (* TODO: rename location to message_number *)
  printf "Message_number: %d\n" sms.SMS.location;
  printf "Is in inbox: %B\n" sms.SMS.inbox_folder;
  printf "Number: %s\n" sms.SMS.number;
  printf "Date and time: %s\n"
    (G.DateTime.os_date_time sms.SMS.date_time);
  printf "Date and time (SMSC): %s\n"
    (G.DateTime.os_date_time sms.SMS.smsc_time);
  printf "Status : %s\n" (string_of_sms_status sms.SMS.state);
  if sms.SMS.udh_header.SMS.udh = SMS.No_udh then
    (* There's no udh so text is raw in the sms message. *)
    printf "%S" sms.SMS.text
  else begin
    (* There's an udh so we have to decode the sms. *)
    let multi_info = SMS.decode_multipart multi_sms
    and print_info info = print_string info.SMS.buffer in
    Array.iter print_info multi_info.SMS.entries
  end;
  printf "\n%!"

let string_of_signal_quality signal =
  sprintf "Signal Strength = %d, %d%%, bit error rate = %d%%"
    signal.G.Info.signal_strength
    signal.G.Info.signal_percent
    signal.G.Info.bit_error_rate

let string_of_info_gprs = function
  | G.Info.Detached -> "Detached"
  | G.Info.Attached -> "Attached"
  | G.Info.Unknown_gprs -> "Unknown"

let string_of_network_state = function
  | G.Info.HomeNetwork -> "Home"
  | G.Info.NoNetwork -> "No Network"
  | G.Info.RoamingNetwork -> "Roaming"
  | G.Info.RegistrationDenied -> "Registration Denied"
  | G.Info.Unknown_network -> "Unknown status"
  | G.Info.RequestingNetwork -> "Requesting"

let string_of_memory_type = function
  | G.ME -> "Internal memory of the mobile equipment"
  | G.SM -> "SIM card memory"
  | G.ON -> "Own numbers"
  | G.DC -> "Dialled calls"
  | G.RC -> "Received calls"
  | G.MC -> "Missed calls"
  | G.MT -> "Combined ME and SIM phonebook"
  | G.FD -> "Fixed dial"
  | G.VM -> "Voice mailbox"
  | G.SL -> "Sent SMS logs"
  | G.QD -> "Quick dialing choices"

let string_of_folder folder =
  let folder_box =
    match folder.SMS.box with
    | SMS.Inbox -> "Inbox"
    | SMS.Outbox -> "Outbox"
  and folder_memory = string_of_memory_type folder.SMS.folder_memory in
  sprintf "%s (%s) in %s" folder.SMS.name folder_box folder_memory
