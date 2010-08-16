let string_of_sms_status = function
  | Gammu.SMS.Sent -> "Sent"
  | Gammu.SMS.Unsent -> "Unsent"
  | Gammu.SMS.Read -> "Read"
  | Gammu.SMS.Unread -> "Unread"

let string_of_signal_quality signal =
  Printf.sprintf "Signal Strength = %d, %d%%, bit error rate = %d%%"
    signal.Gammu.Info.signal_strength
    signal.Gammu.Info.signal_percent
    signal.Gammu.Info.bit_error_rate

let string_of_info_gprs = function
  | Gammu.Info.Detached -> "Detached"
  | Gammu.Info.Attached -> "Attached"
  | Gammu.Info.Unknown_gprs -> "Unknown"

let string_of_network_state = function
  | Gammu.Info.HomeNetwork -> "Home"
  | Gammu.Info.NoNetwork -> "No Network"
  | Gammu.Info.RoamingNetwork -> "Roaming"
  | Gammu.Info.RegistrationDenied -> "Registration Denied"
  | Gammu.Info.Unknown_network -> "Unknown status"
  | Gammu.Info.RequestingNetwork -> "Requesting"

let string_of_memory_type = function
  | Gammu.ME -> "Internal memory of the mobile equipment"
  | Gammu.SM -> "SIM card memory"
  | Gammu.ON -> "Own numbers"
  | Gammu.DC -> "Dialled calls"
  | Gammu.RC -> "Received calls"
  | Gammu.MC -> "Missed calls"
  | Gammu.MT -> "Combined ME and SIM phonebook"
  | Gammu.FD -> "Fixed dial"
  | Gammu.VM -> "Voice mailbox"
  | Gammu.SL -> "Sent SMS logs"
  | Gammu.QD -> "Quick dialing choices"

let string_of_folder folder =
  Printf.sprintf "%s (%s) in %s"
    folder.Gammu.SMS.name
    (match folder.Gammu.SMS.box with
      Gammu.SMS.Inbox -> "Inbox"
    | Gammu.SMS.Outbox -> "Outbox")
    (string_of_memory_type folder.Gammu.SMS.folder_memory)
