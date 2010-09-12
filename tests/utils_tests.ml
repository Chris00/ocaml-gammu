module G = Gammu

let string_of_sms_status =
  function
  | G.SMS.Sent -> "Sent"
  | G.SMS.Unsent -> "Unsent"
  | G.SMS.Read -> "Read"
  | G.SMS.Unread -> "Unread"

let print_multi_sms multi_sms =
  let module P = Printf in
  let module S = Gammu.SMS in
  let sms = multi_sms.(0) in
  print_string "==SMS==\n";
  P.printf "Folder: %d\n" sms.G.SMS.folder;
  (* TODO: rename location to message_number *)
  P.printf "Message_number: %d\n" sms.G.SMS.location;
  P.printf "Is in inbox: %B\n" sms.G.SMS.inbox_folder;
  P.printf "Number: %s\n" sms.G.SMS.number;
  P.printf "Date and time: %s\n"
    (G.DateTime.os_date_time sms.G.SMS.date_time);
  P.printf "Date and time (SMSC): %s\n"
    (G.DateTime.os_date_time sms.G.SMS.smsc_time);
  P.printf "Status : %s\n" (string_of_sms_status sms.G.SMS.state);
  if (sms.G.SMS.udh_header.G.SMS.udh = G.SMS.No_udh) then
    (* There's no udh so text is raw in the sms message. *)
    print_string sms.G.SMS.text
  else begin
    (* There's an udh so we have to decode the sms. *)
    let multi_info = G.SMS.decode_multipart multi_sms
    and print_info info = print_string info.G.SMS.buffer in
    Array.iter print_info multi_info.G.SMS.entries
  end;
  print_newline ();
  flush stdout

let string_of_signal_quality signal =
  Printf.sprintf "Signal Strength = %d, %d%%, bit error rate = %d%%"
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
    match folder.G.SMS.box with
    | G.SMS.Inbox -> "Inbox"
    | G.SMS.Outbox -> "Outbox"
  and folder_memory = string_of_memory_type folder.G.SMS.folder_memory in
  Printf.sprintf "%s (%s) in %s" folder.G.SMS.name folder_box folder_memory
