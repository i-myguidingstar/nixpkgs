import ./make-test.nix ({ pkgs, ...} :

{
  name = "plasma5";
  meta = with pkgs.stdenv.lib.maintainers; {
    maintainers = [ ttuegel ];
  };

  machine = { ... }:
  let
    sddm_theme = pkgs.stdenv.mkDerivation {
      name = "breeze-ocr-theme";
      phases = "buildPhase";
      buildCommand = ''
        mkdir -p $out/share/sddm/themes/
        cp -r ${pkgs.plasma-workspace}/share/sddm/themes/breeze $out/share/sddm/themes/breeze-ocr-theme
        chmod -R +w $out/share/sddm/themes/breeze-ocr-theme
        printf "[General]\ntype=color\ncolor=#1d99f3\nbackground=\n" > $out/share/sddm/themes/breeze-ocr-theme/theme.conf
      '';
    };
  in
  {
    imports = [ ./common/user-account.nix ];
    services.xserver.enable = true;
    services.xserver.displayManager.sddm.enable = true;
    services.xserver.displayManager.sddm.theme = "breeze-ocr-theme";
    services.xserver.desktopManager.plasma5.enable = true;
    services.xserver.desktopManager.default = "plasma5";
    virtualisation.memorySize = 1024;
    environment.systemPackages = [ sddm_theme ];

    # fontconfig-penultimate-0.3.3 -> 0.3.4 broke OCR apparently, but no idea why.
    nixpkgs.config.packageOverrides = superPkgs: {
      fontconfig-penultimate = superPkgs.fontconfig-penultimate.override {
        version = "0.3.3";
        sha256 = "1z76jbkb0nhf4w7fy647yyayqr4q02fgk6w58k0yi700p0m3h4c9";
      };
    };
  };

  enableOCR = true;

  testScript = { nodes, ... }: let
    user = nodes.machine.config.users.users.alice;
    xdo = "${pkgs.xdotool}/bin/xdotool";
  in ''
    startAll;
    # Wait for display manager to start
    $machine->waitForText(qr/${user.description}/);
    $machine->screenshot("sddm");

    # Log in
    $machine->sendChars("${user.password}\n");
    $machine->waitForFile("/home/alice/.Xauthority");
    $machine->succeed("xauth merge ~alice/.Xauthority");

    $machine->waitUntilSucceeds("pgrep plasmashell");
    $machine->waitForWindow("^Desktop ");

    # Check that logging in has given the user ownership of devices.
    $machine->succeed("getfacl /dev/snd/timer | grep -q alice");

    $machine->execute("su - alice -c 'DISPLAY=:0.0 dolphin &'");
    $machine->waitForWindow(" Dolphin");

    $machine->execute("su - alice -c 'DISPLAY=:0.0 konsole &'");
    $machine->waitForWindow("Konsole");

    $machine->execute("su - alice -c 'DISPLAY=:0.0 systemsettings5 &'");
    $machine->waitForWindow("Settings");

    $machine->execute("${xdo} key Alt+F1 sleep 10");
    $machine->screenshot("screen");
  '';
})
