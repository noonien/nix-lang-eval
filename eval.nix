let
  pkgs = import <nixpkgs> {};
  lib = pkgs.lib;
  callPackage = pkgs.callPackage;
  writeScript = pkgs.writeScript;
  runCommand = pkgs.runCommand;
  bash = pkgs.bash;
  mkEvaluator =
    {name, preCommand ? "", command, ...}:
    let 
      mkScript = sname: cmd: if cmd == "" then "true" else 
        writeScript (name + "-eval-" + sname) ''
          #!${bash}/bin/bash
          set -eu
          set -o pipefail

          # redirect stdin and stderr to `out`
          exec >out 2>&1 

          log() {
            echo "$@" >>log
          }

          ${cmd}
        '';
      scripts = builtins.mapAttrs (name: cmd: mkScript name cmd) { inherit preCommand command; };
    in
      writeScript (name + "-eval") ''
        #!${bash}/bin/bash

        # check that the source file exists
        [ -f source ] || { echo "source file does not exist" >&2; exit 1; }

        # remove existing log
        rm -f log

        # create empty input if it doesn't exist or is not a file
        [ -f input ] || { rm -rf input; touch input; }

        if [ -z "$TMP" ]; then
          export TMP=`pwd`/tmp
          mkdir -p $TMP
        fi;

        ${scripts.preCommand} || exit 0
        ${scripts.command} <input || exit 0

        rm -rf tmp
      '';

  mkTests =
    {name, evaluator, tests ? [], ... }@lang:
    let
      runTest = {name, source, input ? "", output}: ''
        {
          echo "running ${lang.name} test ${name}"

          if [ -e "${name}" ]; then
            echo "test directory ${name} already exists"
            exit 1
          fi
          mkdir -p "${name}"; cd "${name}"

          echo -n ${lib.escapeShellArg source} > source
          echo -n ${lib.escapeShellArg input} > input
          echo -n ${lib.escapeShellArg output} > expected-out

          ${evaluator}

          diff expected-out out || {
            echo "source:"
            cat source
            echo
            echo "input:"
            cat input
            exit 1
          }
          cd ..
        }
      '';
        
    in
      writeScript (name + "-eval-test") ''
        set -e
        echo "running ${name} tests"
        ${lib.concatMapStrings (test: "${runTest test}\n") tests}
      '';

  nixRunner = what: setup:
    runCommand (what.name + "-runner") {} ''
      mkdir -p $out; cd $out
      ${setup}
      "${what}"
      status=$?
      echo $status > exit-status
      exit $status
    '';

  nixEvalRunner =
    lang:
      {source, input ? ""}:
        nixRunner lang  ''
          cat ${source} > source
          if [ -f "${input}" ]; then
            cat "${input}" > input
          fi
        '';

  nixTestRunner = tests: nixRunner tests "";

  languages = [
   (callPackage ./bash.nix { inherit mkEvaluator; })
   (callPackage ./go.nix { inherit mkEvaluator; })
   (callPackage ./javascript.nix { inherit mkEvaluator; })
   (callPackage ./lua.nix { inherit mkEvaluator; })
   (callPackage ./perl.nix { inherit mkEvaluator; })
   (callPackage ./php.nix { inherit mkEvaluator; })
   (callPackage ./python.nix { inherit mkEvaluator; })
   (callPackage ./qalculate.nix { inherit mkEvaluator; })
   (callPackage ./rust.nix { inherit mkEvaluator; })
  ];
in
{
  languages = builtins.foldl'
    (x: y: x // y) {}
    (map 
      ({name, aliases ? [], ...}@lang: builtins.listToAttrs
        (map
          (n: lib.nameValuePair n (nixEvalRunner lang.evaluator))
          ([name] ++ aliases)
        )
      ) 
      languages
    );


  list = map ({name, aliases ? null, ...}: { inherit name aliases; }) languages;

  tests = builtins.listToAttrs
    (map
      ({name, ...}@lang: lib.nameValuePair name (nixTestRunner (mkTests lang)))
      languages
    );

    allTests = nixTestRunner 
      (writeScript ("all-languages-tests")
        (lib.flip lib.concatMapStrings languages
          ({name, ...}@lang: ''
            set -e
            {
              mkdir ${name}; cd ${name}
              "${mkTests lang}"
              cd ..
            }
          '')
        )
      );

}
