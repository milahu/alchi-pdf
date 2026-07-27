{ pkgs ? import <nixpkgs> {} }:

with pkgs;

mkShell {
  buildInputs = [

    # embed fonts into PDF files for printing
    # example use:
    # embed-pdf-fonts wersindmeinefreunde.2026-06-18.pdf wersindmeinefreunde.2026-06-18.with-fonts.pdf
    nur.repos.milahu.embed-pdf-fonts

  ];
}
