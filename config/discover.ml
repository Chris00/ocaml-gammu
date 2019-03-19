module C = Configurator.V1

let error_sys sys =
  C.die "System %S currently not supported.  Please \
         contact the OCaml gammu developers." sys

let cflags_default sys =
  if sys = "linux" then
    ["-O3"; "-fPIC"; "-DPIC"; "-I/usr/include/gammu"]
  else if sys = "mingw64" then
    ["-O3"; "-fPIC"; "-DPIC"; "-DHAVE_SSIZE_T"; "-IC:/Gammu/include/gammu"]
  else if sys = "msvc" || sys = "win64" then
    ["/I"; "C:\\Gammu\\include\\gammu"]
  else error_sys sys

let libs_default sys =
  if sys = "linux" then ["-lGammu"; "-lm"]
  else if sys = "msvc" || sys = "win64" then
    ["C:\\Gammu\\lib\\Gammu.lib"]
  else if sys = "mingw64" then
    ["C:\\Gammu\\lib\\Gammu.lib"; "-verbose"]
  else error_sys sys

let configure t =
  let module P = C.Pkg_config in
  let sys = C.ocaml_config_var_exn t "system"in
  let pkg = match P.get t with
    | Some pkg_config -> P.query pkg_config ~package:"gammu"
    | None -> None in
  let cflags = match Sys.getenv "OCAML_GAMMU_CFLAGS" with
    | alt_cflags -> C.Flags.extract_blank_separated_words alt_cflags
    | exception Not_found ->
       match pkg with Some p -> p.P.cflags
                    | None -> cflags_default sys in
  let libs = match Sys.getenv "OCAML_GAMMU_LIBS" with
    | alt_libs -> C.Flags.extract_blank_separated_words alt_libs
    | exception Not_found ->
       match pkg with Some p -> p.P.libs
                    | None -> libs_default sys in

  (* Check for debug environment variable *)
  let debug = try ignore(Sys.getenv "OCAML_GAMMU_DEBUG"); true
              with _ -> false in
  let cflags =
    if debug then
      (if Sys.win32 then "/DCAML_GAMMU_DEBUG"
       else "-DCAML_GAMMU_DEBUG") :: cflags
    else cflags in
  C.Flags.write_sexp "c_flags.sexp" cflags;
  C.Flags.write_sexp "c_library_flags.sexp" libs

let () =
  C.main ~name:"discover" configure
