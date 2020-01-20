{ mkEvaluator, php, ... }:
rec {
  name = "php";

  evaluator = mkEvaluator {
    inherit name;

    preCommand = ''
      cp source source.php
    '';

    command = ''
      exec ${php}/bin/php source.php
    '';
  };

  tests = [
    {
      name = "simple-example";
      source = ''
        <? echo("hello world");
      '';
      output = "hello world";
    }
  ];
}
