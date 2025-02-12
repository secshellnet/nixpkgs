{
  stdenv,
  lib,
  fetchFromGitHub,
  meson,
  pkg-config,
  ninja,
  glib,
  gtk3,
  nemo,
  cmake,
  dbus-glib,
  libcryptui,
  gcr,
  libnotify,
  gnupg,
  gpgme,
}:

stdenv.mkDerivation rec {
  pname = "nemo-seahorse";
  version = "6.4.0";

  src = fetchFromGitHub {
    owner = "linuxmint";
    repo = "nemo-extensions";
    rev = version;
    hash = "sha256-39hWA4SNuEeaPA6D5mWMHjJDs4hYK7/ZdPkTyskvm5Y=";
  };

  sourceRoot = "${src.name}/nemo-seahorse";

  nativeBuildInputs = [
    meson
    pkg-config
    ninja
    cmake
    dbus-glib
    libcryptui
    gcr
    libnotify
    gnupg
  ];

  buildInputs = [
    glib
    gtk3
    nemo
    gpgme
  ];

  PKG_CONFIG_LIBNEMO_EXTENSION_EXTENSIONDIR = "${placeholder "out"}/${nemo.extensiondir}";

  meta = with lib; {
    homepage = "https://github.com/linuxmint/nemo-extensions/tree/master/nemo-seahorse";
    description = "Nemo seahorse extension";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
    maintainers = teams.cinnamon.members;
  };
}
