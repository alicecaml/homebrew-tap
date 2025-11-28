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
    ohai "Patching lock directory to build with homebrew's OCaml compiler..."
    system "patch", "-p1", "-i", "packaging/replace-compiler-version-with-template-in-lockdir.patch"
    ocaml_version = `ocamlopt.opt -version`.strip
    system "find", "dune.lock", "-type", "f", "-exec", "sed", "-i.old", "s/%%COMPILER_VERSION%%/#{ocaml_version}/",
      "{}", ";"

    # Dune doesn't like it when we tamper with the lock directory. Remove the
    # "dependency_hash" line from the manifest so it can't tell what we've
    # done.
    system "sed", "-i.old", "s/(dependency_hash .*)//", "dune.lock/lock.dune"

    # Enable experimental feature so we get build progress to help us debug.
    ENV["DUNE_CONFIG__PKG_BUILD_PROGRESS"] = "enabled"

    # Build and install Alice!
    ohai "Building and installing Alice..."
    system "dune", "build", "@install", "--cache=disabled", "--release", "--only-packages", "alice"
    system "dune", "install", "--prefix=#{prefix}", "alice"
  end

  test do
    # Make a new executable package and run it.
    system bin/"alice", "new", "--exe", "hello"
    system bin/"alice", "run", "--manifest-path", "hello/Alice.toml"
  end
end
