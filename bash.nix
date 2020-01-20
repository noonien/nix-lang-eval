{ mkEvaluator, bash, ... }:
rec {
  name = "bash";
  aliases = [ "sh" ];

  evaluator = mkEvaluator {
    inherit name;

    preCommand = ''
      cp source source.bash
    '';

    command = ''
      exec ${bash}/bin/bash source.bash
    '';
  };

  tests = [
    {
      name = "simple-example";
      source = ''
        echo "hello world"
      '';
      output = "hello world\n";
    }
  ];
}
