class Mtplx < Formula
  PYPI_SOURCE_URL = "https://files.pythonhosted.org/packages/de/5f/577da0bf660f5c1c213761bcc4f874c13bb3e090c86d2de2d6e540e4d56e/mtplx-0.3.7.tar.gz".freeze

  desc "Native MTP speculative decoding for Qwen3-Next on Apple Silicon"
  homepage "https://github.com/youssofal/MTPLX"
  url PYPI_SOURCE_URL
  sha256 "c1a68ad7bee586f85b7b3546bfb112c8c327c2d65713f301c4de5525f6e7c986"
  license "Apache-2.0"

  depends_on arch: :arm64
  depends_on :macos
  depends_on "python@3.13"

  def install
    doc.install "README.md" if File.exist?("README.md")
    prefix.install "LICENSE" if File.exist?("LICENSE")

    %w[mtplx mtplx-tune].each do |command|
      (bin/command).write <<~EOS
        #!/bin/bash
        set -euo pipefail

        VENV="${MTPLX_BREW_VENV:-#{var}/mtplx/venv-#{version}}"
        PYTHON="#{Formula["python@3.13"].opt_bin}/python3.13"

        if [ ! -x "$VENV/bin/#{command}" ]; then
          echo "MTPLX runtime is not installed. Bootstrapping with pip..."
          mkdir -p "$(dirname "$VENV")"
          "$PYTHON" -m venv "$VENV"
          "$VENV/bin/python" -m pip install --upgrade pip
          "$VENV/bin/python" -m pip install --progress-bar on "#{PYPI_SOURCE_URL}"
        fi

        exec "$VENV/bin/#{command}" "$@"
      EOS
    end
  end

  def post_install
    venv = var/"mtplx/venv-#{version}"
    python = Formula["python@3.13"].opt_bin/"python3.13"

    ENV["PIP_NO_INPUT"] = "1"
    ENV["PIP_PROGRESS_BAR"] = "on"
    rm_r venv if venv.exist?
    mkdir_p venv.dirname

    system python, "-m", "venv", venv
    system venv/"bin/python", "-m", "pip", "install", "--upgrade", "pip"
    system venv/"bin/python", "-m", "pip", "install", "--progress-bar", "on", PYPI_SOURCE_URL
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
