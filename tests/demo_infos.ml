(*i Simple demo/test file that gathers some informations about the phone. *)
open Args_demo
open Utils_tests
open Printf

module G = Gammu
module I = Gammu.Info
module S = Gammu.SMS

let print_dyn_infos s =
  begin
    try
      let status = S.get_status s in
      print_string "(#unread) #used/#max:\n";
      printf "(%d) %d/%d (SIM)\t"
        status.S.sim_unread status.S.sim_used status.S.sim_size;
      printf "(%d) %d/%d (Phone)\n"
        status.S.phone_unread status.S.phone_used status.S.phone_size;
      printf "#templates used: %d\n" status.S.templates_used;
    with G.Error G.NOTSUPPORTED ->
      print_string "Your phone doesn't support getting sms status.\n";
  end;
  flush stdout;
  let bat = I.battery_charge s in
  printf "%s\n"
    (match bat.I.charge_state with
    | I.BatteryPowered -> "Powered from battery."
    | I.BatteryConnected -> "Powered from AC, battery connected."
    | I.BatteryCharging -> "Powered from AC, battery is charging."
    | I.BatteryNotConnected -> "Powered from AC, no battery."
    | I.BatteryFull -> "Powered from AC, battery is fully charged."
    | I.PowerFault -> "Power failure.");
  flush stdout;
  printf "Battery (%s): %imAh, %i%%, %imV, %i Celcius\n"
    (match bat.I.battery_type with
    | I.Unknown_battery -> "Unknown"
    | I.NiMH -> "NiMH"
    | I.LiIon -> "LiIon"
    | I.LiPol -> "LiPol")
    bat.I.battery_capacity
    bat.I.battery_percent
    bat.I.battery_voltage
    bat.I.battery_temperature;
  flush stdout;
  printf "Consumption: phone %imA (%i Celcius), charger %imA %imV\n"
    bat.I.phone_current
    bat.I.phone_temperature
    bat.I.charge_current
    bat.I.charge_voltage;
  printf "%s\n" (string_of_signal_quality (I.signal_quality s));
  flush stdout;
  let network = I.network_info s in
  printf "Network %s, %s\n"
    (string_of_network_state network.I.state)
    network.I.name;
  printf "CID \"%s\", code \"%s\", LAC \"%s\"\n"
    network.I.cid network.I.code network.I.lac;
  printf "GPRS %s, packet CID \"%s\", LAC \"%s\", \"%s\"\n"
    (string_of_info_gprs network.I.gprs)
    network.I.packet_cid
    network.I.packet_lac
    (string_of_network_state network.I.packet_state);
  flush stdout;;

let () =
  try
    parse_args ();
    let s = G.make () in
    configure s;
    prepare_phone s;
    printf "Phone model: %s\n" (I.model s);
    printf "Manufacturer: \"%s\" (%s month)\n"
      (I.manufacturer s) (I.manufacture_month s);
    printf "Product code: %s\n" (I.product_code s);
    let fw = I.firmware s in
    printf "Hardware: %s\n" (I.hardware s);
    printf "Firmware version: \"%s\", date \"%s\", num \"%f\"\n"
      fw.I.version fw.I.ver_date fw.I.ver_num;
    printf "IMEI: %s\n" (I.imei s);
    print_string "Folders:\n";
    Array.iteri
      (fun i folder ->
        printf "  %d : %s\n" i (string_of_folder folder))
      (S.folders s);
    print_newline ();
    while true do
      print_dyn_infos s;
      print_string "Press [Enter] to refresh informations.\n";
      ignore (read_line ());
    done
  with G.Error e -> printf "Error: %s\n" (G.string_of_error e)
  (* TODO: Add a trap to disconnect... *)
