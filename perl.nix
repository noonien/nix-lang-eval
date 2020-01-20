{ mkEvaluator, perl, ... }:
rec {
  name = "perl";
  aliases = [ "pl" ];

  evaluator = mkEvaluator {
    inherit name;

    preCommand = ''
      cp source source.pl
    '';

    command = ''
      exec ${perl}/bin/perl source.pl
    '';
  };

  tests = [
    {
      name = "simple-example";
      source = ''
        print "hello world";
      '';
      output = "hello world";
    }
  ];
}
