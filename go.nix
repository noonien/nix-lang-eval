{ lib, pkgs, runCommand, fetchFromGitHub, mkEvaluator, ... }:
let
  packages = [
    {
      package = "github.com/davecgh/go-spew";
      src = fetchFromGitHub {
        owner = "davecgh";
        repo = "go-spew";
        rev = "d8f796af33cc11cb798c1aaeb27a4ebc5099927d";
        sha256 = "19z27f306fpsrjdvkzd61w1bdazcdbczjyjck177g33iklinhpvx";
      };
    }
  ];

  gopath = runCommand "go-source.gopath" {} (''
    export GOPATH=$out
    export GOCACHE=$TMP/go-cache

    mkdir -p $GOPATH

    '' + (lib.flip lib.concatMapStrings packages ({package, src}: ''
    pkg_path=$out/src/${package}
    pkg_base=$(dirname $pkg_path)
    mkdir -p $pkg_base
    ln -s ${src} $pkg_path
  '')));

in
rec {
  name = "go";

  evaluator = mkEvaluator rec {
    inherit name;

    inputs = with pkgs; [ go goimports perl ];

    preCommand = ''
      PATH=${lib.makeBinPath inputs}:$PATH

      # copy file to output
      cat source > source.go

      export GOPATH=${gopath}
      export GOCACHE=$TMP/go-cache

      log "$(go version)"

      # if file does not contain a package directive, we add one
      grep -q '^package' source.go || {
        content=$(cat source.go)

        # if file does not contain a function, we add one
        grep -q '^func' source.go || {
          [[ $(echo "$content" | wc -l) -gt 1 ]] || grep -Eiq 'print|dump' source.go || {
            # if file does not contain a print, we add one to the last line
            content="fmt.Print(($content))"

            log "added fmt.Print to one-liner"
          }

          content=$(echo -e "func main() {\n$content\n}")
          log "wrapped code in func main() {}"
        }

        content=$(echo -e "package main\n$content")
        log "added package main"

        echo "$content" > source.go

        # copy to a temp file, we don't gofmt the original file so we don't lose locations
        cp source.go $TMP/source.go
        gofmt -w $TMP/source.go

        # determine what extra imports we need, and add them to the original file
        new_imports=$(goimports -d $TMP/source.go | grep '^+' | grep -o '".*"')
        new_imports_count=$(echo -n "$new_imports" | grep -c '^')
        if [[ $new_imports_count -gt 0 ]]; then
          # add imports after package directive
          new_imports="$new_imports" perl -pi -e '/package main/ and $_.="import (\n$ENV{'new_imports'}\n)\n"' source.go
          log -e "added new imports:\n$new_imports"
        fi
      }

      go build -o eval source.go

      log "build done"
    '';

    command = ''
      exec ./eval
    '';
  };

  tests = [
    { name = "simple-expr"; source = ''"hello world"''; output = "hello world"; }
    {
      name = "code-with-print";
      source = ''fmt.Print("hello world")'';
      output = "hello world";
    }
    {
      name = "read-from-stdin";
      source = ''
        data, _ := ioutil.ReadAll(os.Stdin)
        fmt.Print(string(data))
      '';
      input = "hello world";
      output = "hello world";
    }
    {
      name = "code-with-functions";
      source = ''
        func main() {
          fmt.Print("hello world")
        }
      '';
      output = "hello world";
    }
    {
      name = "code-with-package";
      source = ''
        package main
        import "fmt"
        func main() {
          fmt.Print("hello world")
        }
      '';
      output = "hello world";
    }
    {
      name = "external-packages";
      source = ''
        spew.Dump("hello world")
      '';
      output = ''
        (string) (len=11) "hello world"
      '';
    }
    {
      name = "error";
      source = ''
        package main
        func main() {
          fmt.Print("hello world")
        }
      '';
      output = ''
        # command-line-arguments
        ./source.go:3:3: undefined: fmt
      '';
    }
  ];
}
