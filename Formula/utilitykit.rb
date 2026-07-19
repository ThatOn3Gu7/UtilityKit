# Homebrew formula for UtilityKit.
#
# Install directly from this repository (no separate tap repo needed):
#   brew tap thaton3gu7/utilitykit https://github.com/ThatOn3Gu7/UtilityKit.git
#   brew install utilitykit          # stable (tagged release)
#   brew install --HEAD utilitykit   # latest master, no release required
#
# Releasing: after pushing a new `vX.Y.Z` tag, run
#   bash packaging/update-formula.sh vX.Y.Z
# to point `url`/`sha256` below at the new tarball. Until the first tag
# exists, the stable block carries a placeholder checksum and only
# `--HEAD` installs work.
class Utilitykit < Formula
  desc "Suite of 51 self-contained Bash terminal tools behind one dashboard"
  homepage "https://github.com/ThatOn3Gu7/UtilityKit"
  url "https://github.com/ThatOn3Gu7/UtilityKit/archive/refs/tags/v5.10.0.tar.gz"
  sha256 "ac1c799c3de831a9f8d899c885c153a5cbd968e8a0d2dcca6f6b21134bee5ba4"
  license "MIT"
  head "https://github.com/ThatOn3Gu7/UtilityKit.git", branch: "master"

  # The suite uses associative arrays and other bash >= 4 features;
  # macOS ships bash 3.2, so always run through Homebrew's bash.
  depends_on "bash"

  def install
    bash_completion.install "completions/utility.bash" => "utility"
    zsh_completion.install "completions/utility.zsh" => "_utility"

    libexec.install "main.sh", "lib", "modules", "docs", "CHANGES.md"
    libexec.install "README.md" => "README.md"

    (bin/"utility").write <<~SH
      #!/bin/bash
      exec "#{Formula["bash"].opt_bin}/bash" "#{libexec}/main.sh" "$@"
    SH
  end

  def caveats
    <<~EOS
      The launcher is installed as `utility`:
        utility           # interactive dashboard
        utility help      # list all CLI routes
      Many tools shell out to optional commands (git, jq, ffmpeg, ...);
      `utility doctor` reports what is available on this machine.
    EOS
  end

  test do
    output = shell_output("#{bin}/utility version")
    assert_match(/UtilityKit v\d+\.\d+\.\d+/, output)
  end
end
