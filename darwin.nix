{
  lib,
  stdenv,
  fetchurl,
  jdk,
  makeWrapper,
}: let
  version = lib.removeSuffix "\n" (lib.fileContents ./VERSION);
  burpHash = lib.removeSuffix "\n" (lib.fileContents ./BURP_SHA256);

  burpSrc = fetchurl {
    name = "burpsuite.jar";
    urls = [
      "https://github.com/xiv3r/Burpsuite-Professional/releases/download/burpsuite-pro/burpsuite_pro_v${version}.jar"
    ];
    sha256 = burpHash;
  };

  loaderSrc = ./.;
  pname = "burpsuitepro";
  productName = "pro";
  productDesktop = "BurpSuite Professional";
  description = "An integrated platform for performing security testing of web applications";
in
  stdenv.mkDerivation {
    inherit pname version;
    src = burpSrc;
    dontUnpack = true;

    nativeBuildInputs = [ makeWrapper ];

    installPhase = ''
      mkdir -p $out/share $out/bin

      cp ${burpSrc} $out/share/burpsuite_pro_v${version}.jar
      cp ${loaderSrc}/loader.jar $out/share/loader.jar

      # Main launcher
      makeWrapper ${jdk}/bin/java $out/bin/${pname} \
        --add-flags "--add-opens=java.desktop/javax.swing=ALL-UNNAMED" \
        --add-flags "--add-opens=java.base/java.lang=ALL-UNNAMED" \
        --add-flags "--add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED" \
        --add-flags "--add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED" \
        --add-flags "--add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED" \
        --add-flags "-javaagent:$out/share/loader.jar" \
        --add-flags "-noverify" \
        --add-flags "-jar $out/share/burpsuite_pro_v${version}.jar"

      # Key loader launcher
      makeWrapper ${jdk}/bin/java $out/bin/loader \
        --add-flags "-jar $out/share/loader.jar"
    '';

    meta = with lib; {
      inherit description;
      longDescription = ''
        Burp Suite is an integrated platform for performing security testing of web applications.
        Its various tools work seamlessly together to support the entire testing process, from
        initial mapping and analysis of an application's attack surface, through to finding and
        exploiting security vulnerabilities.
      '';
      homepage = "https://github.com/xiv3r/Burpsuite-Professional";
      changelog =
        "https://portswigger.net/burp/releases/professional-community-"
        + replaceStrings ["."] ["-"] version;
      sourceProvenance = with sourceTypes; [binaryBytecode];
      license = licenses.unfree;
      platforms = lib.platforms.darwin;
      hydraPlatforms = [];
      maintainers = [];
      mainProgram = pname;
    };
  }
