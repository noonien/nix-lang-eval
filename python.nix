{ mkEvaluator, python3, ... }:
rec {
  name = "python";
  aliases = [ "python3" "py" "py3" ];

  evaluator = mkEvaluator {
    inherit name;

    preCommand = ''
      cp source source.py
    '';

    command = ''
      exec ${python3}/bin/python source.py
    '';
  };

  tests = [
    {
      name = "simple-example";
      source = ''
        print("hello world")
      '';
      output = "hello world\n";
    }
  ];
}
