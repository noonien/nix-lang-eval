{ mkEvaluator, nodejs, ... }:
rec {
  name = "javascript";
  aliases = [ "js" "node" "nodejs" ];

  evaluator = mkEvaluator {
    inherit name;

    preCommand = ''
      cp source source.js
    '';

    command = ''
      exec ${nodejs}/bin/node source.js
    '';
  };

  tests = [
    {
      name = "simple-example";
      source = ''
        console.log("hello world")
      '';
      output = "hello world\n";
    }
  ];
}
