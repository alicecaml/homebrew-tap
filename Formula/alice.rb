class Alice < Formula
  desc "Radical OCaml build system"
  homepage "https://github.com/alicecaml/alice"
  url "https://github.com/alicecaml/alice/archive/refs/tags/0.1.3.tar.gz"
  sha256 "be121ecfd7b51f6be1c2dc7039cf3c880f1ba723dc9cbd45ad6f5548ccfa8b1f"
  license "MIT"

  depends_on "dune" => :build
  depends_on "ocaml" => :build

  def install
    # We want to use the OCaml compiler installed with homebrew to build Alice,
    # but it's not known ahead of time what version the compiler will be. Alice
    # depends on the Opam package ocaml-system to prevent Dune from building
    # the compiler (which would take too long). Do some surgery on the lock
    # directory so the specified compiler version matches the version of the
    # compiler currently installed by homebrew. Patch some lockfiles to expect
    # whatever version of the compiler homebrew has installed.
    system "patch", "-p1", "-i", "packaging/replace-compiler-version-with-template-in-lockdir.patch"
    ocaml_version = `ocamlopt.opt -version`.strip
    system "find", "dune.lock", "-type", "f", "-exec", "sed", "-i.old", "s/%%COMPILER_VERSION%%/#{ocaml_version}/", "{}", ";"

    # Dune's packaging mechanism is optimized for local development but doesn't
    # handle building a single package from a project containing multiple
    # packages. Hopefully this gets fixed, but in the meantime we have to
    # remove the lockfiles for packages that aren't dependencies of the "alice"
    # package (the additional packages are used for testing Alice).
    [
      "base.v0.17.3.pkg",
      "csexp.1.5.2.pkg",
      "dune-configurator.3.20.2.pkg",
      "jane-street-headers.v0.17.0.pkg",
      "jst-config.v0.17.0.pkg",
      "ocaml-compiler-libs.v0.17.0.pkg",
      "ocaml_intrinsics_kernel.v0.17.1.pkg",
      "ppx_assert.v0.17.0.pkg",
      "ppx_base.v0.17.0.pkg",
      "ppx_cold.v0.17.0.pkg",
      "ppx_compare.v0.17.0.pkg",
      "ppx_derivers.1.2.1.pkg",
      "ppx_enumerate.v0.17.0.pkg",
      "ppx_expect.v0.17.3.pkg",
      "ppx_globalize.v0.17.2.pkg",
      "ppx_hash.v0.17.0.pkg",
      "ppx_here.v0.17.0.pkg",
      "ppx_inline_test.v0.17.1.pkg",
      "ppx_optcomp.v0.17.1.pkg",
      "ppx_sexp_conv.v0.17.1.pkg",
      "ppxlib.0.37.0.pkg",
      "ppxlib_jane.v0.17.4.pkg",
      "sexplib0.v0.17.0.pkg",
      "stdio.v0.17.0.pkg",
      "time_now.v0.17.0.pkg",
    ].each { |f|
      system "rm", "dune.lock/#{f}"
    }

    # Dune doesn't like it when we tamper with the lock directory. Remove the
    # "dependency_hash" line from the manifest so it can't tell what we've
    # done.
    system "sed", "-i.old", "s/(dependency_hash .*)//", "dune.lock/lock.dune"

    # Enable experimental feature so we get build progress to help us debug.
    ENV["DUNE_CONFIG__PKG_BUILD_PROGRESS"] = "enabled"

    # Build and install Alice!
    system "dune", "build", "@install", "--release", "--only-packages", "alice"
    system "dune", "install", "--prefix=#{prefix}", "alice"
  end

  test do
    # Make a new executable package and run it.
    system bin/"alice", "new", "--exe", "hello"
    system bin/"alice", "run", "--manifest-path", "hello/Alice.toml"
  end
end
