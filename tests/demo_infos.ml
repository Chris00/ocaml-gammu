(*i Simple demo/test file that gathers some informations about the phone. *)
open Gammu
open Utils_demo

let print_dyn_infos s =
  let status = SMS.get_status s in
  print_string "(#unread) #used/#max:\n";
  Printf.printf "(%d) %d/%d (SIM)\t"
    status.SMS.sim_unread status.SMS.sim_used status.SMS.sim_size;
  Printf.printf "(%d) %d/%d (Phone)\n"
    status.SMS.phone_unread status.SMS.phone_used status.SMS.phone_size;
  Printf.printf "#templates used: %d\n" status.SMS.templates_used;
  flush stdout;
  let bat = Info.battery_charge s in
  Printf.printf "%s\n"
    (match bat.Info.charge_state with
      Info.BatteryPowered -> "Powered from battery."
    | Info.BatteryConnected -> "Powered from AC, battery connected."
    | Info.BatteryCharging -> "Powered from AC, battery is charging."
    | Info.BatteryNotConnected -> "Powered from AC, no battery."
    | Info.BatteryFull -> "Powered from AC, battery is fully charged."
    | Info.PowerFault -> "Power failure.");
  flush stdout;
  Printf.printf "Battery (%s): %imAh, %i%%, %imV, %i Celius\n"
    (match bat.Info.battery_type with
      Info.Unknown_battery -> "Unknown"
    | Info.NiMH -> "NiMH"
    | Info.LiIon -> "LiIon"
    | Info.LiPol -> "LiPol")
    bat.Info.battery_capacity
    bat.Info.battery_percent
    bat.Info.battery_voltage
    bat.Info.battery_temperature;
  flush stdout;
  Printf.printf "Consumption: phone %imA (%i Celcius), charger %imA %imV\n"
    bat.Info.phone_current
    bat.Info.phone_temperature
    bat.Info.charge_current
    bat.Info.charge_voltage;
  let signal = Info.signal_quality s in
  Printf.printf "Signal Strength = %i, %i%%\n"
    signal.Info.signal_strength signal.Info.signal_percent;
  flush stdout;
  let network = Info.network_info s
  and string_of_network_state = function
    | Info.HomeNetwork -> "Home"
    | Info.NoNetwork -> "No Network"
    | Info.RoamingNetwork -> "Roaming"
    | Info.RegistrationDenied -> "Registration Denied"
    | Info.Unknown_network -> "Unknown status"
    | Info.RequestingNetwork -> "Requesting"
  in
  Printf.printf "Network %s, %s\n"
    (string_of_network_state network.Info.state)
    network.Info.name;
  Printf.printf "CID \"%s\", code \"%s\", LAC \"%s\"\n"
    network.Info.cid network.Info.code network.Info.lac;
  Printf.printf "GPRS %s, packet CID \"%s\", LAC \"%s\", \"%s\"\n"
    (match network.Info.gprs with
      Info.Detached -> "Detached"
    | Info.Attached -> "Attached"
    | Info.Unknown_gprs -> "Unknown")
    network.Info.packet_cid
    network.Info.packet_lac
    (string_of_network_state network.Info.packet_state);
  flush stdout;;

let () =
  parse_args ();
  let s = make () in
  configure s;
  prepare_phone s;
  Printf.printf "Phone model: %s\n" (Info.model s);
  Printf.printf "Manufacturer: \"%s\" (%s month)\n"
    (Info.manufacturer s) (Info.manufacture_month s);
  Printf.printf "Product code: %s\n" (Info.product_code s);
  let f = Info.firmware s in
  Printf.printf "Hardware: %s\n" (Info.hardware s);
  Printf.printf "Firmware version: \"%s\", date \"%s\", num \"%i\"\n"
    f.Info.version f.Info.ver_date f.Info.ver_num;
  Printf.printf "IMEI: %s\n" (Info.imei s);
  print_newline ();
  while true do
    print_dyn_infos s;
    print_string "Press [Enter] to refresh informations.\n";
    ignore (read_line ());
  done;;
  (* TODO: Add a trap to disconnect... *)
