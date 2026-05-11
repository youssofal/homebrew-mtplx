class Mtplx < Formula
  PYPI_SOURCE_URL = "https://files.pythonhosted.org/packages/1a/eb/e4ce38fc0ff3facf643c5b8cd9c27cfad221d22d772fcc876df8fb68533a/mtplx-0.3.2.tar.gz".freeze

  desc "Native MTP speculative decoding for Qwen3-Next on Apple Silicon"
  homepage "https://github.com/youssofal/MTPLX"
  url PYPI_SOURCE_URL
  sha256 "d938bbca88f2ac166f2e2cbf382f25fae3ded2837832a0be6b7bfc25de51f83d"
  license "Apache-2.0"

  depends_on "python@3.13"

  on_macos do
    on_intel do
      odie "MTPLX requires Apple Silicon because MLX does not support Intel Mac inference."
    end
  end

  def install
    doc.install "README.md" if File.exist?("README.md")
    prefix.install "LICENSE" if File.exist?("LICENSE")

    (bin/"mtplx").write <<~EOS
      #!/bin/bash
      set -euo pipefail

      VENV="${MTPLX_BREW_VENV:-#{var}/mtplx/venv-#{version}}"
      PYTHON="#{Formula["python@3.13"].opt_bin}/python3.13"

      if [ ! -x "$VENV/bin/mtplx" ]; then
        echo "MTPLX runtime is not installed. Bootstrapping with pip..."
        mkdir -p "$(dirname "$VENV")"
        "$PYTHON" -m venv "$VENV"
        "$VENV/bin/python" -m pip install --upgrade pip
        "$VENV/bin/python" -m pip install --progress-bar on "#{PYPI_SOURCE_URL}"
      fi

      exec "$VENV/bin/mtplx" "$@"
    EOS
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
    system var/"mtplx/venv-#{version}/bin/python", "-c",
           "import fastapi, huggingface_hub, mlx, mlx_lm, numpy, pydantic, rich, safetensors, uvicorn"
  end
end
