{
  description = "Run pdflatex on all .tex files, output to ./out, optional latexindent formatting";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.${system}.pdflatex = 
let 
         pkgs = pkgs.texlive.combine {
            inherit (pkgs.texlive) scheme-medium
              minted upquote
              tcolorbox
              latexindent;
          };
          in 
      pkgs.writeShellApplication {
        name = "build-pdf";
        runtimeInputs = [pkgs];
        text = ''
          format=false

          while [[ $# -gt 0 ]]; do
            case "$1" in
              --format)
                format=true
                shift
                ;;
              *)
                echo "Unknown option: $1"
                exit 1
                ;;
            esac
          done

          mkdir -p ./out

          pwd
          for file in ./*.tex; do
            if $format; then
              echo "Formatting $file with latexindent..."
              latexindent -s -g ./out/indent.log -o "$file" "$file"
            else
              echo "Compiling $file..."
              pdflatex -output-directory=./out -halt-on-error -interaction=nonstopmode -shell-escape "$file"
            fi
          done

          echo "Done. PDFs are in ./out"
        '';
      };

      apps.${system}.default = {
        type = "app";
        program = "${self.packages.${system}.pdflatex}/bin/build-pdf";
      };

      formatter.${system} = pkgs.nixfmt-rfc-style;
    };
}
