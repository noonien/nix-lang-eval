{ mkEvaluator, lua, ... }:
rec {
  name = "lua";

  evaluator = mkEvaluator {
    inherit name;

    preCommand = ''
      cp source source.lua
    '';

    command = ''
      exec ${lua}/bin/lua source.lua
    '';
  };

  tests = [
    {
      name = "simple-example";
      source = ''
        print("hello world");
      '';
      output = "hello world\n";
    }
  ];
}
