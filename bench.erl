#!/usr/bin/env escript

-mode(compile).

main([Path]) ->
  main([Path, "100"]);

main([Path, Count_]) ->
  Count = list_to_integer(Count_),
  {ok,Bin} = file:read_file(Path),
  List = binary_to_list(Bin),
  code:add_pathz("ebin"),
  Self = self(),
  T0 = os:timestamp(),
  spawn(fun() ->
    code:add_pathz("_build/bench/lib/parsexml/ebin"),
    loop_parsexml(Bin, Count),
    Self ! {ready, parsexml, timer:now_diff(os:timestamp(),T0),process_info(self(),memory)} end),
  spawn(fun() ->
    code:add_pathz("_build/bench/lib/exml/ebin"),
    loop_exml(Bin, Count),
    Self ! {ready, exml, timer:now_diff(os:timestamp(),T0),process_info(self(),memory)} end),
  spawn(fun() ->
    code:add_pathz("_build/bench/lib/fast_xml/ebin"),
    code:add_pathz("_build/bench/lib/p1_utils/ebin"),
    {ok, _} = application:ensure_all_started(fast_xml),
    loop_fast_xml(Bin, Count),
    Self ! {ready, fast_xml, timer:now_diff(os:timestamp(),T0),process_info(self(),memory)} end),
  spawn(fun() ->
    code:add_pathz("_build/bench/lib/exomler/ebin"),
    code:add_pathz("_build/bench/lib/parselib/ebin"),
    {ok, _} = application:ensure_all_started(exomler),
    loop_exomler(Bin, Count),
    Self ! {ready, exomler, timer:now_diff(os:timestamp(),T0),process_info(self(),memory)} end),
  spawn(fun() ->
    loop_xmerl(List, Count),
    Self ! {ready, xmerl, timer:now_diff(os:timestamp(),T0),process_info(self(),memory)} end),

  spawn(fun() ->
    code:add_pathz("_build/bench/lib/erlsom/ebin"),
    case code:load_file(erlsom) of
      {error, _} -> Self ! {ready, erlsom, 9999999, {memory,0}};
      _ ->
        loop_erlsom(Bin, Count), 
        Self ! {ready, erlsom, timer:now_diff(os:timestamp(),T0),process_info(self(),memory)} 
    end
  end),


  Size = Count*size(Bin),
  receive
    {ready,   xmerl,T1,{memory,M1}} -> io:format("   xmerl: ~8.. Bms ~8.. BKB ~BMB/s~n", [T1 div 1000,M1 div 1024, Size div T1])
  end,
  receive
    {ready,parsexml,T2,{memory,M2}} -> io:format("parsexml: ~8.. Bms ~8.. BKB ~BMB/s~n", [T2 div 1000,M2 div 1024, Size div T2])
  end,
  receive
    {ready,  erlsom,T3,{memory,M3}} -> io:format("  erlsom: ~8.. Bms ~8.. BKB ~BMB/s~n", [T3 div 1000,M3 div 1024, Size div T3])
  end,
  receive
    {ready,exml,T4,{memory,M4}} -> io:format("    exml: ~8.. Bms ~8.. BKB ~BMB/s~n", [T4 div 1000,M4 div 1024, Size div T4])
  end,
  receive
    {ready,fast_xml,T5,{memory,M5}} -> io:format("fast_xml: ~8.. Bms ~8.. BKB ~BMB/s~n", [T5 div 1000,M5 div 1024, Size div T5])
  end,
  receive
    {ready,exomler,T6,{memory,M6}} -> io:format(" exomler: ~8.. Bms ~8.. BKB ~BMB/s~n", [T6 div 1000,M6 div 1024, Size div T6])
  end,
  ok.

loop_parsexml(_Bin,0) -> ok;
loop_parsexml(Bin,Count) ->
  _A = parsexml:parse(Bin),
  loop_parsexml(Bin,Count-1).

loop_exomler(_Bin,0) -> ok;
loop_exomler(Bin,Count) ->
  _A = exomler:decode(Bin),
  loop_parsexml(Bin,Count-1).

loop_xmerl(_Bin,0) -> ok;
loop_xmerl(Bin,Count) ->
  _A = xmerl_scan:string(Bin),
  loop_xmerl(Bin,Count-1).

loop_erlsom(_,0) -> ok;
loop_erlsom(Bin,Count) ->
  _A = erlsom:simple_form(Bin),
  loop_erlsom(Bin,Count-1).

loop_exml(_,0) -> ok;
loop_exml(Bin,Count) ->
  _A = exml:parse(Bin),
  loop_exml(Bin,Count-1).

loop_fast_xml(_,0) -> ok;
loop_fast_xml(Bin,Count) ->
  _A = fxml_stream:parse_element(Bin),
  loop_fast_xml(Bin, Count-1).
