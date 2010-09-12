(* Simple demo/test file that prints some informations and the first sms. *)
open Args_demo
open Utils_tests
open Printf

module G = Gammu

let read_all s folder =
  let begin_time = Unix.gettimeofday () in
  let c =
    try
      G.SMS.fold s ~folder
        ~on_err:(fun loc e ->
          printf "Failed to get SMS next to location %i: %s\n"
            loc (G.string_of_error e);
          flush stdout;
          Unix.sleep 1)
        (fun c m -> print_multi_sms m; c + 1) 0;
    with G.Error G.NOTSUPPORTED | G.Error G.NOTIMPLEMENTED ->
      failwith "Sorry but your phone doesn't support GetNext \
                or it is not implemented.\n"
  in
  let elapsed_time = Unix.gettimeofday () -. begin_time in
  printf "\n%i message(s) read in %fsecs\n" c elapsed_time

let () =
  try
    parse_args ();
    let s = G.make () in
    configure s;
    prepare_phone s;
    print_string "Start reading from folder: ";
    let folder = int_of_string (read_line ()) in
    read_all s folder
  with G.Error e -> printf "Error: %s\n" (G.string_of_error e)
(* TODO: add trap to disconnect *)

