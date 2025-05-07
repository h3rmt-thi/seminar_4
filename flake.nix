{
  description = "Flake for LaTeX formatting and Spectre vulnerability demonstration";
  inputs.nixpkgs.url = "github:nixos/nixpkgs";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      latexDeps = (pkgs.texlive.combine { inherit (pkgs.texlive) scheme-small minted upquote tcolorbox latexindent; });
    in
    {
      packages.${system} =
        {
          latex-format = pkgs.writeShellApplication {
            name = "latex-format";
            runtimeInputs = [ latexDeps ];
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
            runtimeInputs = [ latexDeps ];
            text = ''
              cd ./beamer
              if [ ! -d "./out" ]; then
                mkdir -p ./out
                pdflatex -output-directory=./out -halt-on-error -interaction=nonstopmode -shell-escape "./Beamer.tex"
              fi
              pdflatex -output-directory=./out -halt-on-error -interaction=nonstopmode -shell-escape "./Beamer.tex"
            '';
          };

          present-pdf = pkgs.writeShellApplication {
            name = "present-pdf";
            text = ''
              cd ./beamer/out
              echo "Starting presentation with pdfpc..."
              ${pkgs.pdfpc}/bin/pdfpc -d 60 --page-transition "fade:0.4" Beamer.pdf
            '';
          };

          spectre = pkgs.stdenv.mkDerivation {
            name = "spectre";
            src = ./code/spectre;
            nativeBuildInputs = [ pkgs.gcc14 pkgs.bintools ];
            buildPhase = ''
              mkdir -p ./out
              gcc -std=c11 -O0 -o ./out/spectre spectre.c dependency1/unlock.c dependency1/unlock.h dependency2/attacker.c dependency2/attacker.h
            '';
            installPhase = ''
              mkdir -p $out/bin
              cp ./out/spectre $out/bin/
            '';
          };

          run-spectre = pkgs.writeShellApplication {
            name = "run-spectre";
            runtimeInputs = [ ];
            text = ''
              grep -q "mitigations=off" /proc/cmdline && echo "Mitigations are off" || echo "Mitigations are not off"
              cd ./code/spectre
              until ${self.packages.${system}.spectre}/bin/spectre; do
              sleep 0.1
              done
            '';
          };
        };

      formatter.${system} = pkgs.nixpkgs-fmt;

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          self.packages.${system}.latex-format
          self.packages.${system}.latex-build
          self.packages.${system}.run-spectre
          self.packages.${system}.present-pdf
        ];
      };
    };
}
