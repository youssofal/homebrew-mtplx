class Mtplx < Formula
  SOURCE_URL = "https://github.com/youssofal/MTPLX/releases/download/v2.13.3/mtplx-2.13.3.tar.gz".freeze
  # The prebuilt wheel for this formula's Python, with the native executor inside (macOS 14 and newer),
  # so an install never compiles: a source build needs Xcode's newest SDK and otherwise runs without it.
  WHEEL_URL = "https://github.com/youssofal/MTPLX/releases/download/v2.13.3/mtplx-2.13.3-cp313-cp313-macosx_14_0_arm64.whl".freeze

  desc "Run Inkling 2 Mini and Qwen 3.8 on Apple Silicon with native MTP decoding"
  homepage "https://mtplx.com"
  url SOURCE_URL
  sha256 "1b7b38916f7bca81a32ea3533c980d2dd9028dea4dbeda66c0fe581d259b5148"
  license "Apache-2.0"

  depends_on arch: :arm64
  depends_on :macos
  depends_on "python@3.13"

  # The Python this formula runs on. Homebrew's helper for this path, the bare
  # `formula_opt_bin`, only exists from Homebrew 6.0.3 (June 2026): every 5.x release and
  # 6.0.0 through 6.0.2 raise NoMethodError on it while `brew install` writes the launcher
  # (issue #486). This is the same stable opt path that helper builds, spelled out so the
  # formula loads on every Homebrew, without a formula object as the style cop asks.
  def python_bin
    HOMEBREW_PREFIX/"opt/python@3.13/bin"
  end

  def install
    doc.install "README.md" if File.exist?("README.md")
    prefix.install "LICENSE" if File.exist?("LICENSE")

    %w[mtplx mtplx-tune].each do |command|
      (bin/command).write <<~EOS
        #!/bin/bash
        set -euo pipefail

        VENV="${MTPLX_BREW_VENV:-#{var}/mtplx/venv-#{version}}"
        PYTHON="#{python_bin}/python3.13"

        if [ ! -x "$VENV/bin/#{command}" ]; then
          echo "MTPLX runtime is not installed. Bootstrapping with pip..."
          mkdir -p "$(dirname "$VENV")"
          "$PYTHON" -m venv "$VENV"
          "$VENV/bin/python" -m pip install --upgrade pip
          "$VENV/bin/python" -m pip install --progress-bar on "#{WHEEL_URL}"
        fi

        exec "$VENV/bin/#{command}" "$@"
      EOS
    end
  end

  def post_install
    venv = var/"mtplx/venv-#{version}"
    python = python_bin/"python3.13"

    ENV["PIP_NO_INPUT"] = "1"
    ENV["PIP_PROGRESS_BAR"] = "on"
    rm_r venv if venv.exist?
    mkdir_p venv.dirname

    system python, "-m", "venv", venv
    system venv/"bin/python", "-m", "pip", "install", "--upgrade", "pip"
    system venv/"bin/python", "-m", "pip", "install", "--progress-bar", "on", WHEEL_URL
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/mtplx --version")
    assert_match "MTPLX", shell_output("#{bin}/mtplx help")
    assert_match "dry-run: no model will be loaded",
                 shell_output("#{bin}/mtplx-tune --model models/not-loaded-in-dry-run --dry-run --yes")
    system var/"mtplx/venv-#{version}/bin/python", "-c",
           "import fastapi, huggingface_hub, mlx, mlx_lm, numpy, pydantic, rich, safetensors, uvicorn"
  end
end
