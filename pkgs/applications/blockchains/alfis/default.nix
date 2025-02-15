{ stdenv, lib, fetchFromGitHub, rustPlatform, pkg-config, withGui ? true
, webkitgtk, Cocoa, WebKit, zenity, makeWrapper }:

rustPlatform.buildRustPackage rec {
  pname = "alfis";
  version = "0.6.5";

  src = fetchFromGitHub {
    owner = "Revertron";
    repo = "Alfis";
    rev = "v${version}";
    sha256 = "1g95yvkvlj78bqrk3p2xbhrmg1hrlgbyr1a4s7vg45y60zys2c2j";
  };

  cargoSha256 = "1n7kb1lyghpkgdgd58pw8ldvfps30rnv5niwx35pkdg74h59hqgj";

  checkFlags = [
    # these want internet access, disable them
    "--skip=dns::client::tests::test_tcp_client"
    "--skip=dns::client::tests::test_udp_client"
  ];

  nativeBuildInputs = [ pkg-config makeWrapper ];
  buildInputs = lib.optional (withGui && stdenv.isLinux) webkitgtk
    ++ lib.optionals (withGui && stdenv.isDarwin) [ Cocoa WebKit ];

  buildNoDefaultFeatures = true;
  buildFeatures = lib.optional withGui "webgui";

  postInstall = lib.optionalString (withGui && stdenv.isLinux) ''
    wrapProgram $out/bin/alfis \
      --prefix PATH : ${lib.makeBinPath [ zenity ]}
  '';

  meta = with lib; {
    description = "Alternative Free Identity System";
    homepage = "https://alfis.name";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ misuzu ];
    platforms = platforms.unix;
  };
}
