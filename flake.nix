{
  description = "Flake for LaTeX formatting and Spectre vulnerability demonstration";
  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system} =
        {
          latex-format = pkgs.writeShellApplication {
            name = "latex-format";
            runtimeInputs = [ (pkgs.texlive.combine { inherit (pkgs.texlive) scheme-minimal latexindent; }) ];
            text = ''
              cd ./beamer
              for file in ./*.tex; do
                echo "Formatting $file with latexindent..."
                latexindent -s -g ./out/indent.log -o "$file" "$file"
              done
            '';
          };

          latex-build = pkgs.writeShellApplication {
            name = "latex-build";
            runtimeInputs = [ (pkgs.texlive.combine { inherit (pkgs.texlive) scheme-small minted upquote tcolorbox; }) ];
            text = ''
              cd ./beamer
              mkdir -p ./out
              echo "\setbeameroption{hide notes}" > ./.config.tex
              pdflatex -output-directory=./out -halt-on-error -interaction=nonstopmode -shell-escape "./Beamer.tex"
              cp ./out/Beamer.pdf ./Beamer.pdf
            '';
          };

          latex-build-notes = pkgs.writeShellApplication {
            name = "latex-build-notes";
            runtimeInputs = [ (pkgs.texlive.combine { inherit (pkgs.texlive) scheme-small minted upquote tcolorbox; }) ];
            text = ''
              cd ./beamer
              mkdir -p ./out-2
              echo "\setbeameroption{show notes on second screen=right}" > ./.config.tex
              pdflatex -output-directory=./out-2 -halt-on-error -interaction=nonstopmode -shell-escape "./Beamer.tex"
              cp ./out-2/Beamer.pdf ./Beamer-notes.pdf
            '';
          };

          run-spectre = pkgs.writeShellApplication {
            name = "run-spectre";
            runtimeInputs = [ pkgs.gcc ];
            text = ''
              cd ./code/spectre/
              mkdir -p ./out
              gcc -std=c11 -march=native -o ./out/spectre spectre.c dependency1/unlock.c dependency1/unlock.h dependency2/attacker.c dependency2/attacker.h
              grep -q "mitigations=off" /proc/cmdline && echo "Mitigations are off" || echo "Mitigations are not off"
              until ./out/spectre; do :; done
            '';
          };
        };

      formatter.${system} = pkgs.nixpkgs-fmt;
    };
}
