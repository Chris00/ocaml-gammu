(* OASIS_START *)
(* OASIS_STOP *)
(* Ocamlbuild_plugin.dispatch dispatch_default;; *)

open Ocamlbuild_plugin;;

let rec split_on is_delim s i0 i i1 =
  if i >= i1 then [String.sub s i0 (i1 - i0)]
  else if is_delim s.[i] then
    String.sub s i0 (i - i0) :: skip is_delim s (i + 1) i1
  else
    split_on is_delim s i0 (i + 1) i1
and skip is_delim s i i1 =
  if i >= i1 then []
  else if is_delim s.[i] then skip is_delim s (i + 1) i1
  else split_on is_delim s i (i + 1) i1

let is_space c = c = ' ' || c = '\t' || c = '\r' || c = '\n'

let split_on_spaces s = split_on is_space s 0 0 (String.length s)

let cflags, cclib =
  let env = BaseEnvLight.load () in (* setup.data *)
  let cflags = split_on_spaces (BaseEnvLight.var_get "gammu_cflags" env) in
  let cclib = split_on_spaces (BaseEnvLight.var_get "gammu_libs" env) in
  cflags, cclib
;;

dispatch
  (MyOCamlbuildBase.dispatch_combine [
    dispatch_default;
    begin function
    | After_rules ->
      let includes = ["gammu_stubs.h"; "io.h"] in
      let includes = List.map (fun f -> "src" / f) includes in
      dep ["c"; "compile"] includes;

      flag ["pkg_config_gammu"; "compile"; "c"]
        (S (List.fold_right (fun o l -> A "-ccopt" :: A o :: l) cflags []));
      flag ["pkg_config_gammu"; "link"]
        (S (List.fold_right (fun o l -> A "-cclib" :: A o :: l) cclib []));
      flag ["ocamlmklib"; "c"]
        (S (List.map (fun o -> A o) cclib));

    | _ -> ()
    end;
  ]);;
