{ mkEvaluator, libqalculate, ... }:
rec {
  name = "qalculate";
  aliases = [ "qalc" "calc" "q" ];

  evaluator = mkEvaluator {
    inherit name;

    preCommand = ''
      mkdir -p $TMP/.config
      cp source source.qalc
    '';

    command = ''
      exec ${libqalculate}/bin/qalc -terse -file source.qalc
    '';
  };

  tests = [
    {
      name = "simple-example";
      source = ''
        33 + 9
      '';
      output = "42\n";
    }
  ];
}
