[lock_file_path | _] = System.argv()
{lock_map, _} = Code.eval_file(lock_file_path)
[:hex,:phoenix,version] ++ _rest = Tuple.to_list(Map.get(lock_map,:"phoenix"))
IO.puts(version)
