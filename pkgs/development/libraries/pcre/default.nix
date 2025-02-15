{ lib, stdenv, fetchurl
, pcre, windows ? null
, variant ? null
}:

with lib;

assert elem variant [ null "cpp" "pcre16" "pcre32" ];

let
  version = "8.44";
  pname = if (variant == null) then "pcre"
    else  if (variant == "cpp") then "pcre-cpp"
    else  variant;

in stdenv.mkDerivation {
  name = "${pname}-${version}";

  src = fetchurl {
    url = "mirror://sourceforge/project/pcre/pcre/${version}/pcre-${version}.tar.bz2";
    sha256 = "0v9nk51wh55pcbnf2jr36yarz8ayajn6d7ywiq2wagivn9c8c40r";
  };

  outputs = [ "bin" "dev" "out" "doc" "man" ];

  # Disable jit on Apple Silicon, https://github.com/zherczeg/sljit/issues/51
  configureFlags = optional (!stdenv.hostPlatform.isRiscV && !(stdenv.hostPlatform.isDarwin && stdenv.hostPlatform.isAarch64)) "--enable-jit" ++ [
    "--enable-unicode-properties"
    "--disable-cpp"
  ]
    ++ optional (variant != null) "--enable-${variant}";

  # https://bugs.exim.org/show_bug.cgi?id=2173
  patches = [ ./stacksize-detection.patch ];

  preCheck = ''
    patchShebangs RunGrepTest
  '';

  doCheck = !(with stdenv.hostPlatform; isCygwin || isFreeBSD) && stdenv.hostPlatform == stdenv.buildPlatform;
    # XXX: test failure on Cygwin
    # we are running out of stack on both freeBSDs on Hydra

  postFixup = ''
    moveToOutput bin/pcre-config "$dev"
  ''
    + optionalString (variant != null) ''
    ln -sf -t "$out/lib/" '${pcre.out}'/lib/libpcre{,posix}.{so.*.*.*,*dylib}
  '';

  meta = {
    homepage = "http://www.pcre.org/";
    description = "A library for Perl Compatible Regular Expressions";
    license = lib.licenses.bsd3;

    longDescription = ''
      The PCRE library is a set of functions that implement regular
      expression pattern matching using the same syntax and semantics as
      Perl 5. PCRE has its own native API, as well as a set of wrapper
      functions that correspond to the POSIX regular expression API. The
      PCRE library is free, even for building proprietary software.
    '';

    platforms = platforms.all;
  };
}
