(* Simple demo/test file that gathers some informations about the phone. *)
open Printf
open Gammu
open Args_demo
open Utils_tests

let print_dyn_infos s =
  begin
    try
      let status = SMS.get_status s in
      print_string "(#unread) #used/#max:\n";
      printf "(%d) %d/%d (SIM)\t"
        status.SMS.sim_unread status.SMS.sim_used status.SMS.sim_size;
      printf "(%d) %d/%d (Phone)\n"
        status.SMS.phone_unread status.SMS.phone_used status.SMS.phone_size;
      printf "#templates used: %d\n" status.SMS.templates_used;
    with Error NOTSUPPORTED ->
      print_string "Your phone doesn't support getting sms status.\n";
  end;
  flush stdout;
  let bat = Info.battery_charge s in
  printf "%s\n"
    (match bat.Info.charge_state with
      Info.BatteryPowered -> "Powered from battery."
    | Info.BatteryConnected -> "Powered from AC, battery connected."
    | Info.BatteryCharging -> "Powered from AC, battery is charging."
    | Info.BatteryNotConnected -> "Powered from AC, no battery."
    | Info.BatteryFull -> "Powered from AC, battery is fully charged."
    | Info.PowerFault -> "Power failure.");
  flush stdout;
  printf "Battery (%s): %imAh, %i%%, %imV, %i Celius\n"
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
  printf "Consumption: phone %imA (%i Celcius), charger %imA %imV\n"
    bat.Info.phone_current
    bat.Info.phone_temperature
    bat.Info.charge_current
    bat.Info.charge_voltage;
  printf "%s\n" (string_of_signal_quality (Info.signal_quality s));
  flush stdout;
  let network = Info.network_info s in
  printf "Network %s, %s\n"
    (string_of_network_state network.Info.state)
    network.Info.name;
  printf "CID \"%s\", code \"%s\", LAC \"%s\"\n"
    network.Info.cid network.Info.code network.Info.lac;
  printf "GPRS %s, packet CID \"%s\", LAC \"%s\", \"%s\"\n"
    (string_of_info_gprs network.Info.gprs)
    network.Info.packet_cid
    network.Info.packet_lac
    (string_of_network_state network.Info.packet_state);
  flush stdout;;

let () =
  parse_args ();
  let s = make () in
  configure s;
  prepare_phone s;
  printf "Phone model: %s\n" (Info.model s);
  printf "Manufacturer: \"%s\" (%s month)\n"
    (Info.manufacturer s) (Info.manufacture_month s);
  printf "Product code: %s\n" (Info.product_code s);
  let fw = Info.firmware s in
  printf "Hardware: %s\n" (Info.hardware s);
  printf "Firmware version: \"%s\", date \"%s\", num \"%f\"\n"
    fw.Info.version fw.Info.ver_date fw.Info.ver_num;
  printf "IMEI: %s\n" (Info.imei s);
  print_string "Folders:\n";
  Array.iteri
    (fun i folder -> printf "  %d : %s\n" i (string_of_folder folder))
    (SMS.folders s);
  print_newline ();
  print_dyn_infos s;
  (* TODO: Add a trap to disconnect... *)
