{
  lib,
  fetchFromGitHub ? null,
  release_version ? null,
  gitRelease ? null,
  officialRelease ? null,
  monorepoSrc' ? null,
  version ? null,
}@args:

rec {
  llvm_meta = {
    license =
      with lib.licenses;
      [ ncsa ]
      ++
        # Contributions after June 1st, 2024 are only licensed under asl20 and
        # llvm-exception: https://github.com/llvm/llvm-project/pull/92394
        lib.optionals (lib.versionAtLeast release_version "19") [
          asl20
          llvm-exception
        ];
    maintainers = lib.teams.llvm.members;

    # See llvm/cmake/config-ix.cmake.
    platforms =
      lib.platforms.aarch64
      ++ lib.platforms.arm
      ++ lib.platforms.mips
      ++ lib.platforms.power
      ++ lib.platforms.s390x
      ++ lib.platforms.wasi
      ++ lib.platforms.x86
      ++ lib.optionals (lib.versionAtLeast release_version "7") lib.platforms.riscv
      ++ lib.optionals (lib.versionAtLeast release_version "14") lib.platforms.m68k
      ++ lib.optionals (lib.versionAtLeast release_version "16") lib.platforms.loongarch64;
  };

  releaseInfo =
    if gitRelease != null then
      rec {
        original = gitRelease;
        release_version = args.version or original.version;
        version = gitRelease.rev-version;
      }
    else
      rec {
        original = officialRelease;
        release_version = args.version or original.version;
        version =
          if original ? candidate then "${release_version}-${original.candidate}" else release_version;
      };

  monorepoSrc =
    if monorepoSrc' != null then
      monorepoSrc'
    else
      let
        sha256 = releaseInfo.original.sha256;
        rev = if gitRelease != null then gitRelease.rev else "llvmorg-${releaseInfo.version}";
      in
      fetchFromGitHub rec {
        owner = "llvm";
        repo = "llvm-project";
        inherit rev sha256;
        passthru = { inherit owner repo rev; };
      };

}
