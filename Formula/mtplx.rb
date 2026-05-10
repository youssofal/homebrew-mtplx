class Mtplx < Formula
  desc "Native MTP speculative decoding for Qwen3-Next on Apple Silicon"
  homepage "https://github.com/youssofal/MTPLX"
  url "https://files.pythonhosted.org/packages/d2/69/afca3b9c3dbcc958b17c1a262c31bf8455d77a7810d3fec0b3fa6755e432/mtplx-0.3.0.tar.gz"
  sha256 "6cb3e02f3d76f061879938026b87594babf59591d9234683bfb21545a1b3da85"
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
        "$VENV/bin/python" -m pip install --progress-bar on "mtplx==#{version}"
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
    system venv/"bin/python", "-m", "pip", "install", "--progress-bar", "on", "mtplx==#{version}"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/mtplx --version")
    assert_match "MTPLX", shell_output("#{bin}/mtplx help")
    system var/"mtplx/venv-#{version}/bin/python", "-c",
           "import fastapi, huggingface_hub, mlx, mlx_lm, numpy, pydantic, rich, safetensors, uvicorn"
  end
end
