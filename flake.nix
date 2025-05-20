{
  description = "Flake for LaTeX formatting and Spectre vulnerability demonstration";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      latexPackages = (pkgs.texlive.combine { inherit (pkgs.texlive) scheme-small minted upquote tcolorbox biblatex csquotes latexindent biber; });
    in
    {
      packages.${system} =
        {
          beamer-format = pkgs.writeShellApplication {
            name = "beamer-format";
            runtimeInputs = [ latexPackages ];
            text = ''
              cd ./beamer
              mkdir -p ./out
              for file in ./*.tex; do
                echo "Formatting $file with latexindent..."
                latexindent -s -g ./out/indent.log -o "$file" "$file"
              done
            '';
          };
          document-format = pkgs.writeShellApplication {
            name = "document-format";
            runtimeInputs = [ latexPackages ];
            text = ''
              cd ./document
              mkdir -p ./out
              for file in ./*.tex; do
                echo "Formatting $file with latexindent..."
                latexindent -s -g ./out/indent.log -o "$file" "$file"
              done
            '';
          };

          beamer-build = pkgs.writeShellApplication {
            name = "beamer-build";
            runtimeInputs = [ latexPackages ];
            text = ''
              cd ./beamer
              # run twice to get toc right
              if [ ! -d "./out" ]; then
                mkdir -p ./out
                pdflatex -output-directory=./out -halt-on-error -interaction=nonstopmode -shell-escape "./Beamer.tex"
              fi
              pdflatex -output-directory=./out -halt-on-error -interaction=nonstopmode -shell-escape "./Beamer.tex"

            '';
          };
          document-build = pkgs.writeShellApplication {
            name = "document-build";
            runtimeInputs = [ latexPackages ];
            text = ''
              cd ./document
              # run twice to get toc right
              if [ ! -d "./out" ]; then
                mkdir -p ./out
                pdflatex -output-directory=./out -halt-on-error -interaction=nonstopmode -shell-escape "./Document.tex"
                biber ./out/Document
              fi
              pdflatex -output-directory=./out -halt-on-error -interaction=nonstopmode -shell-escape "./Document.tex"
              echo "Running biber..."
              biber ./out/Document
              echo "Running pdflatex again..."
              pdflatex -output-directory=./out -halt-on-error -interaction=nonstopmode -shell-escape "./Document.tex"
            '';
          };

          beamer-present = pkgs.writeShellApplication {
            name = "beamer-present";
            text = ''
              echo "Starting presentation with pdfpc..."
              sleep 1

              hyprctl dispatch workspace 22 # focus empty workspace
              hyprctl dispatch workspace 5  # focus empty workspace
              (sleep 1; hyprctl dispatch focusmonitor eDP-1; echo "focus sec monitor")&

              # close after open (only converts notes file to json)
              pdfpc -d 60 -g -R ./beamer/out/Beamer.pdfpc --page-transition "fade:0.4" --note-format=markdown ./beamer/out/Beamer.pdf
              jq '.disableMarkdown = true' ./beamer/out/Beamer.pdfpc > ./beamer/out/Beamer.tmp && mv ./beamer/out/Beamer.tmp ./beamer/out/Beamer.pdfpc
              
              sleep 0.5
              (sleep 1; hyprctl dispatch focusmonitor eDP-1; echo "focus sec monitor")&
              pdfpc -d 60 -g -R ./beamer/out/Beamer.pdfpc --page-transition "fade:0.4" --note-format=markdown ./beamer/out/Beamer.pdf
              
              hyprctl dispatch workspace 3 # focus vscode
            '';
          };

          spectre-run = pkgs.writeShellApplication {
            name = "spectre-run";
            runtimeInputs = [ ];
            text = ''
              grep -q "mitigations=off" /proc/cmdline && echo "Mitigations are off" || echo "Mitigations are not off"
              cd ./code/spectre
              until ${self.packages.${system}.spectre}/bin/spectre; do
              sleep 0.1
              done
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
        };

      formatter.${system} = pkgs.nixpkgs-fmt;

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          self.packages.${system}.beamer-format
          self.packages.${system}.beamer-build
          self.packages.${system}.document-format
          self.packages.${system}.document-build
          self.packages.${system}.spectre-run
          self.packages.${system}.beamer-present
          # idk why but pdfpc from nix doesnt render the notes (install in host to fix)
          # pkgs.pdfpc
        ];
      };
    };
}
