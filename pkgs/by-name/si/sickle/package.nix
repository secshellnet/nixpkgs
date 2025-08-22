{
  lib,
  python3,
  fetchFromGitHub,
}:

python3.pkgs.buildPythonApplication rec {
  pname = "sickle";
  version = "4.0.0";
  pyproject = true;
  
  src = fetchFromGitHub {
    owner = "wetw0rk";
    repo = "Sickle";
    tag = "v${version}-Beta";
    hash = "sha256-gMzYiNDtv7+Z96tIPYbhkdNxpL++HDkguNrWpNKtBGM=";
  };
  sourceRoot = "${src.name}/src";

  build-system = [ python3.pkgs.setuptools ];
  
  meta = {
    description = "Payload Development Framework";
    homepage = "https://github.com/wetw0rk/Sickle";
    changelog = "https://github.com/wetw0rk/Sickle/releases/tag/${src.tag}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ felbinger ];
  };
}
