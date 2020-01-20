{ lib, pkgs, mkEvaluator, ... }:
rec {
  name = "rust";
  aliases = [ "rs" ];

  evaluator = mkEvaluator rec {
    inherit name;

    inputs = with pkgs; [ rustc gcc ];
    PATH=lib.makeBinPath inputs;

    opts = lib.concatStringsSep " " [
      "--color never"
      "-C opt-level=0"
      "-C prefer-dynamic"
      "-C debuginfo=0"
      "-v" "--error-format short"
      "-C codegen-units=1"
    ];

    preCommand = ''
      PATH=${lib.makeBinPath inputs}:$PATH
      cp source source.rs

      # if file does not contain a function, we add one
      grep -q '^fn' source.rs || {
        content=$(cat source.rs)

        [[ $(echo "$content" | wc -l) -gt 1 ]] || grep -Eiq 'print' source.rs || {
          # if file does not contain a print, we add one to the last line
          content="print!(\"{}\", ($content))"

          log "added print! to one-liner"
        }

        content=$(echo -e "fn main() {\n$content\n}")
        log "wrapped code in func main() {}"

        echo "$content" > source.rs
      }

      rustc ${opts} -o eval source.rs
    '';

    command = ''
      exec ./eval
    '';
  };

  tests = [
    {
      name = "simple-expr";
      source = ''"hello world"'';
      output = "hello world";
    }
    {
      name = "simple-code";
      source = ''
        fn main() {
          print!("hello world");
        }
      '';
      output = "hello world";
    }
  ];
}
