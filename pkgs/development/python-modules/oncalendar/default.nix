{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pytestCheckHook,
}:

buildPythonPackage rec {
  pname = "oncalendar";
  version = "1.1";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "cuu508";
    repo = "oncalendar";
    tag = "v${version}";
    hash = "sha256-MPKzC2QYA3tWxg19URKheAbPaiS0jXP96xR0Hyl58V0=";
  };

  nativeBuildInputs = [ pytestCheckHook ];

  pythonImportsCheck = [ "oncalendar" ];

  meta = with lib; {
    description = "Systemd OnCalendar expression parser and evaluator";
    homepage = "https://github.com/cuu508/oncalendar";
    license = licenses.bsd3;
    maintainers = with maintainers; [ phaer ];
  };
}
