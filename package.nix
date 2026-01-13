{
  lib,
  stdenv,
  fetchFromGitHub,

  # Build system
  meson,
  ninja,
  pkg-config,
  wrapQtAppsHook,

  # Qt6 dependencies
  qtbase,
  qtdeclarative,
  qtwebsockets,
  qtwebengine,
  qtwebchannel,
  qt5compat,
  qtsvg,
  qtshadertools,
  # Audio backend
  libjack2,

  # Other dependencies
  openssl,
  libsamplerate,
  python3,

  # Optional
  help2man,
  gzip,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "jacktrip";
  version = "2.7.1";

  src = fetchFromGitHub {
    owner = "jacktrip";
    repo = "jacktrip";
    rev = "v${finalAttrs.version}";
    hash = "sha256-6hQKust4Zd6UPfK+KRzJMo00urXTnqY17IcwFEJoG80=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    wrapQtAppsHook
    python3 # Required for metainfo generation on Linux
  ]
  ++ lib.optionals stdenv.isLinux [
    help2man
    gzip
  ];

  buildInputs = [
    # Qt6 modules (common to all platforms)
    qtbase
    qtdeclarative
    qt5compat
    qtsvg
    qtshadertools
    qtwebsockets

    # Audio
    libjack2

    # Other
    openssl
    libsamplerate # Use nixpkgs version instead of subproject
  ]
  ++ lib.optionals (!stdenv.isDarwin) [
    # Virtual Studio dependencies (Linux only, due to Qt6 framework issues on macOS)
    qtwebengine
    qtwebchannel
  ];

  mesonFlags = [
    "-Dqtversion=6"
    "-Djack=enabled"
    "-Drtaudio=disabled"
    "-Dweakjack=false"
    "-Dnoupdater=true"
    "-Dnogui=false"
    "-Dnooscpp=false"
    "-Dnoclassic=false"
    "-Dnofeedback=false"
    "-Dlibsamplerate=enabled"
    "-Dqtedition=opensource"
    "-Dprofile=default"
    "-Dbuildinfo=v${finalAttrs.version}-nix"
  ]
  ++ lib.optionals stdenv.isLinux [
    # Virtual Studio enabled on Linux (full Qt6 WebEngine support)
    "-Dnovs=false"
  ]
  ++ lib.optionals stdenv.isDarwin [
    # Virtual Studio disabled on macOS (Qt6 framework header issues)
    "-Dnovs=true"
  ];

  # Meson will use provided libsamplerate from buildInputs
  # instead of downloading subproject

  # Handle bundled dependencies (oscpp, Simple-FFT)
  # These are header-only and included in source, no action needed

  # The repository has a 'build' script which conflicts with Meson's default build directory
  mesonBuildType = "plain";
  mesonBuildDir = "builddir";

  postPatch = lib.optionalString stdenv.isLinux ''
    # Ensure metainfo script uses our Python
    patchShebangs linux/add_changelog_to_metainfo.py
  '';

  # Fix Qt6 framework header paths on macOS
  env = lib.optionalAttrs stdenv.isDarwin {
    NIX_CFLAGS_COMPILE = "-F${qtbase}/lib -iframework ${qtbase}/lib";
  };

  meta = with lib; {
    description = "High-quality system for audio network performances over the Internet";
    longDescription = ''
      JackTrip is a multi-machine audio system for network music performance
      over the Internet. It supports any number of channels of bidirectional,
      high quality, uncompressed audio signal streaming with the JACK audio
      connection kit.

      This build includes:
      - Linux: Full GUI with Virtual Studio (Qt6 WebEngine)
      - macOS: Classic GUI mode (Virtual Studio disabled due to Qt6 framework limitations)
    '';
    homepage = "https://jacktrip.github.io/jacktrip/";
    license = with licenses; [
      gpl3Plus
      lgpl3Plus
      mit
    ];
    maintainers = with maintainers; [ ];
    platforms = platforms.unix;
    mainProgram = "jacktrip";
  };
})
