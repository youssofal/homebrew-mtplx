class Mtplx < Formula
  PYPI_SOURCE_URL = "https://files.pythonhosted.org/packages/c5/3c/6ee0c3c6fc661b44d18cad99bc4e2d07178b37a446d9d7bdc0107254e785/mtplx-0.3.6.tar.gz".freeze

  desc "Native MTP speculative decoding for Qwen3-Next on Apple Silicon"
  homepage "https://github.com/youssofal/MTPLX"
  url PYPI_SOURCE_URL
  sha256 "5d2a3953bac102824db174c7c4ef25f9d0d9c9f15404d32555211eac93f0df64"
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
