{
  description = "Pinned development boundary for Jolt, Chez Emscripten, and Raylib experiments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    jolt = {
      url = "git+https://github.com/jolt-lang/jolt.git?rev=447b874d06066d15fee187200fabaf410f4ff5b6&submodules=1";
      flake = false;
    };
    chezScheme = {
      url = "git+https://github.com/cisco/ChezScheme.git?rev=7fadeee45fcc0135b17f5c1a926157004f898339&submodules=1";
      flake = false;
    };
    raylib = {
      url = "https://github.com/raysan5/raylib/archive/9f3cadf1e618f125bd9b282c7759f8cb26ce17fc.tar.gz";
      flake = false;
    };
    raylib-jlt = {
      url = "https://github.com/jlt-commons/raylib-jlt/archive/7685ed987aa2dc27ab2499f2804bb28b793d6638.tar.gz";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, jolt, chezScheme, raylib, raylib-jlt }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      mkJolt = pkgs:
        pkgs.stdenv.mkDerivation {
          pname = "jolt";
          version = "447b874d";
          src = jolt;
          strictDeps = true;
          nativeBuildInputs = [ pkgs.chez pkgs.makeWrapper pkgs.pkg-config pkgs.xxd ];
          buildInputs = [ pkgs.lz4 pkgs.zlib pkgs.ncurses pkgs.openssl ]
            ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.libuuid ];
          dontConfigure = true;
          buildPhase = "scheme --script host/chez/build-jolt.ss release target/release/jolt";
          installPhase = ''
            install -Dm755 target/release/jolt "$out/bin/jolt"
            wrapProgram "$out/bin/jolt" \
              --prefix PATH : "${pkgs.lib.makeBinPath [ pkgs.git pkgs.unzip ]}" \
              --set-default JOLT_OPENSSL_LIBDIR "${pkgs.lib.makeLibraryPath [ pkgs.openssl ]}" \
              --set-default SSL_CERT_FILE "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
          '';
        };
    in {
      packages = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; };
        in { jolt = mkJolt pkgs; });
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          pinnedJolt = mkJolt pkgs;
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [
              bash
              chez
              chromium
              cmake
              d2
              emscripten
              file
              gnumake
              git
              nodejs
              ncurses
              ninja
              pinnedJolt
              pkg-config
              patch
              python3
              xxd
            ];
            shellHook = ''
              export JOLT_SOURCE=${jolt}
              export JOLT_BIN=${pinnedJolt}/bin/jolt
              export CHEZ_SOURCE=${chezScheme}
              export RAYLIB_SOURCE=${raylib}
              export RAYLIB_JLT_SOURCE=${raylib-jlt}
            '';
          };
        });
    };
}
