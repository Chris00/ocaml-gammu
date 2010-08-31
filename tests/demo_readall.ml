(* Simple demo/test file that prints some informations and the first sms. *)
open Gammu
open Args_demo
open Utils_tests
open Printf

let () =
  parse_args ();
  let s = make () in
  configure s;
  prepare_phone s;
  print_string "Start reading from folder: ";
  let folder = int_of_string (read_line ()) in
  let begin_time = Unix.gettimeofday () in
  let c =
    try
      SMS.fold s ~folder
        ~on_err:(fun loc e ->
          printf "Failed to get SMS next to location %i: %s\n"
            loc (string_of_error e);
          flush stdout;
          Unix.sleep 1)
        (fun c m -> print_multi_sms m; c + 1) 0;
    with Error NOTSUPPORTED | Error NOTIMPLEMENTED ->
      failwith "Sorry but your phone doesn't support GetNext \
                 or it is not implemented.\n"
  in
  let elapsed_time = Unix.gettimeofday () -. begin_time in
  Printf.printf "\n%i message(s) read in %fsecs\n" c elapsed_time
(* TODO: add trap to disconnect *)

