{ lib, stdenv, fetchurl, pkg-config, cmake, libyamlcpp,
  libevdev, udev }:

let
  version = "0.6.6";
  baseName = "interception-tools";
in stdenv.mkDerivation {
  name = "${baseName}-${version}";

  src = fetchurl {
    url = "https://gitlab.com/interception/linux/tools/-/archive/v${version}/tools-v${version}.tar.gz";
    sha256 = "1vmg53vagh3m2q96n8jviwmm5gp7jm7iispp43v4wlf715qyn5v9";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ libevdev udev libyamlcpp boost];

  prePatch = ''
    substituteInPlace CMakeLists.txt --replace \
      '"/usr/include/libevdev-1.0"' \
      "\"$(pkg-config --cflags libevdev | cut -c 3-)\""
  '';

  meta = {
    description = "A minimal composable infrastructure on top of libudev and libevdev";
    homepage = "https://gitlab.com/interception/linux/tools";
    license = lib.licenses.gpl3;
    maintainers = [ lib.maintainers.vyp ];
    platforms = lib.platforms.linux;
  };
}
