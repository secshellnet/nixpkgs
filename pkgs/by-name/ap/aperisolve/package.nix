{
  lib,
  python3Packages,
  fetchFromGitHub,

  redis,
  rq,

  zip,
  p7zip,
  binwalk,
  foremost,
  exiftool,
  steghide,
  binutils,
  outguess,
  pngcheck,
  zsteg,
}:
let
  inherit (python3Packages)
    buildPythonApplication
    setuptools
    flask
    flask-sqlalchemy
    numpy
    psycopg2-binary
    pillow
    gunicorn
    ;
in
buildPythonApplication rec {
  pname = "aperisolve";
  version = "3.0.5";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Zeecka";
    repo = "AperiSolve";
    tag = version;
    hash = "sha256-cqqgHm2SXrqVcq3MKoGwojA8Z0SUXBS1HvXma9SRCO0=";
  };

  build-system = [ setuptools ];

  patches = [
    ./add-pyproject-toml.patch
  ];

  dependencies = [
    flask
    flask-sqlalchemy
    numpy
    psycopg2-binary
    pillow
    gunicorn

    redis
    rq

    zip
    p7zip
    binwalk
    foremost
    exiftool
    steghide
    binutils
    outguess
    pngcheck
    zsteg
  ];

  meta = {
    description = "Steganalysis web platform";
    homepage = "https://github.com/Zeecka/AperiSolve";
    changelog = "https://github.com/Zeecka/AperiSolve/releases/tag/${src.tag}";
    license = lib.licenses.unfree; # no license provided
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ felbinger ];
  };
}
