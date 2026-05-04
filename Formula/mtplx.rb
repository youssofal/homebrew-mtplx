class Mtplx < Formula
  include Language::Python::Virtualenv

  desc "Native MTP speculative decoding for Qwen3-Next on Apple Silicon"
  homepage "https://github.com/youssofal/MTPLX"
  url "https://files.pythonhosted.org/packages/ff/91/3d1253088bf7e0b1ada2672b28d57a7c70dd58dc727b077a95cb9285eeaa/mtplx-0.1.0rc1.tar.gz"
  sha256 "883e94f995b7a42011dc1dacc49c0a8110fd356c7e8f5174eb69831f8ed6a681"
  license "Apache-2.0"
  revision 1

  depends_on "python@3.13"

  on_macos do
    on_intel do
      odie "MTPLX requires Apple Silicon because MLX does not support Intel Mac inference."
    end
  end

  def install
    python = Formula["python@3.13"].opt_bin/"python3.13"
    virtualenv_create(libexec, python)

    ENV["PIP_NO_INPUT"] = "1"
    ENV["PIP_PROGRESS_BAR"] = "on"
    system libexec/"bin/python", "-m", "pip", "install", "--upgrade", "pip"
    system libexec/"bin/python", "-m", "pip", "install", "--progress-bar", "on", buildpath

    bin.install_symlink libexec/"bin/mtplx"
  end

  test do
    assert_match "mtplx", shell_output("#{bin}/mtplx --version")
    assert_match "MTPLX", shell_output("#{bin}/mtplx help")
    system libexec/"bin/python", "-c",
           "import fastapi, huggingface_hub, mlx, mlx_lm, numpy, pydantic, rich, safetensors, uvicorn"
  end
end
