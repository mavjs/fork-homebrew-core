class Openvino < Formula
  desc "Open Visual Inference And Optimization toolkit for AI inference"
  homepage "https://docs.openvino.ai"
  url "https://github.com/openvinotoolkit/openvino/archive/refs/tags/2023.2.0.tar.gz"
  sha256 "419b3137a1a549fc5054edbba5b71da76cbde730e8a271769126e021477ad47b"
  license "Apache-2.0"
  head "https://github.com/openvinotoolkit/openvino.git", branch: "master"

  livecheck do
    url :stable
    regex(/^(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any,                 arm64_sonoma:   "4b446279dd917f2331fca5566c6bd90cf27c024ccffd86de2488049236fff9cd"
    sha256 cellar: :any,                 arm64_ventura:  "546e12c9e50018b9edb3bc93c9828d010a68fb92e1c27cea3e0a2f150cff3016"
    sha256 cellar: :any,                 arm64_monterey: "2507b59d22416ba1dee76bcf44373a5241059c98c4b0c95b6a766e9eba4dcaea"
    sha256 cellar: :any,                 arm64_big_sur:  "9d31597763c9b11e02faa4e3b51ba66c99c75de9c805cc8a85c71a4997eb72e5"
    sha256 cellar: :any,                 sonoma:         "8c2c44f72fedb5767f9a81f03bb0ec3c421d1eb232d76c5baa8936927b071c39"
    sha256 cellar: :any,                 ventura:        "b9a275c2942faa9115749a87da6445b2fb7f4e62f096f69f7122e814a7a9c856"
    sha256 cellar: :any,                 monterey:       "b8710c8918cdf4870977998b195a6f77c75e255f8f151299be58b098bd5dc84d"
    sha256 cellar: :any,                 big_sur:        "d3f479b8c8910eeb2159946cefb2669aec7a9f9988ddb203bd99a935be8ecd69"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "e249baf6055f0b00678adb1f5c1dd99919f7336b871fc0ae468d9836c60dac14"
  end

  depends_on "cmake" => [:build, :test]
  depends_on "cython" => :build
  depends_on "flatbuffers" => :build
  depends_on "pkg-config" => [:build, :test]
  depends_on "protobuf@21" => :build
  depends_on "pybind11" => :build
  depends_on "python@3.11" => [:build, :test]
  depends_on "numpy"
  depends_on "pugixml"
  depends_on "snappy"
  depends_on "tbb"

  on_linux do
    depends_on "opencl-clhpp-headers" => :build
    depends_on "opencl-headers" => :build
    depends_on "rapidjson" => :build
    depends_on "opencl-icd-loader"

    resource "onednn_gpu" do
      url "https://github.com/oneapi-src/oneDNN/archive/284ad4574939fa784e4ddaa1f4aa577b8eb7a017.tar.gz"
      sha256 "16f36078339cd08b949efea1d863344cb0b742d9f5898937d07a591b0c4da517"
    end
  end

  on_arm do
    depends_on "scons" => :build

    resource "arm_compute" do
      url "https://github.com/ARM-software/ComputeLibrary/archive/refs/tags/v23.08.tar.gz"
      sha256 "62f514a555409d4401e5250b290cdf8cf1676e4eb775e5bd61ea6a740a8ce24f"
    end
  end

  on_intel do
    depends_on "xbyak" => :build
  end

  resource "ade" do
    url "https://github.com/opencv/ade/archive/refs/tags/v0.1.2d.tar.gz"
    sha256 "edefba61a33d6cd4b78a9976cb3309c95212610a81ba6dade09882d1794198ff"
  end

  resource "mlas" do
    url "https://github.com/openvinotoolkit/mlas/archive/f6425b1394334822390fcd9da12788c9cd0d11da.tar.gz"
    sha256 "707a6634d62ea5563042a67161472b4be3ffe73c9783719519abdd583b0295f4"
  end

  resource "onednn_cpu" do
    url "https://github.com/openvinotoolkit/oneDNN/archive/2ead5d4fe5993a797d9a7a4b8b5557b96f6ec90e.tar.gz"
    sha256 "3c51d577f9e7e4cbd94ad08d267502953ec64513241dda6595b2608fafc8314c"
  end

  resource "onnx" do
    url "https://github.com/onnx/onnx/archive/refs/tags/v1.14.1.tar.gz"
    sha256 "e296f8867951fa6e71417a18f2e550a730550f8829bd35e947b4df5e3e777aa1"
  end

  def python3
    "python3.11"
  end

  def install
    # Remove git cloned 3rd party to make sure formula dependencies are used
    dependencies = %w[thirdparty/ade thirdparty/ocl
                      thirdparty/xbyak thirdparty/gflags
                      thirdparty/ittapi thirdparty/snappy
                      thirdparty/pugixml thirdparty/protobuf
                      thirdparty/onnx/onnx thirdparty/flatbuffers
                      src/plugins/intel_cpu/thirdparty/mlas
                      src/plugins/intel_cpu/thirdparty/onednn
                      src/plugins/intel_gpu/thirdparty/rapidjson
                      src/plugins/intel_gpu/thirdparty/onednn_gpu
                      src/plugins/intel_cpu/thirdparty/ComputeLibrary]
    dependencies.each { |d| (buildpath/d).rmtree }

    resource("ade").stage buildpath/"thirdparty/ade"
    resource("onnx").stage buildpath/"thirdparty/onnx/onnx"
    resource("mlas").stage buildpath/"src/plugins/intel_cpu/thirdparty/mlas"
    resource("onednn_cpu").stage buildpath/"src/plugins/intel_cpu/thirdparty/onednn"

    if Hardware::CPU.arm?
      resource("arm_compute").stage buildpath/"src/plugins/intel_cpu/thirdparty/ComputeLibrary"
    elsif OS.linux?
      resource("onednn_gpu").stage buildpath/"src/plugins/intel_gpu/thirdparty/onednn_gpu"
    end

    cmake_args = std_cmake_args + %w[
      -DCMAKE_OSX_DEPLOYMENT_TARGET=
      -DENABLE_CPPLINT=OFF
      -DENABLE_CLANG_FORMAT=OFF
      -DENABLE_NCC_STYLE=OFF
      -DENABLE_TEMPLATE=OFF
      -DENABLE_INTEL_GNA=OFF
      -DENABLE_PYTHON=OFF
      -DENABLE_SAMPLES=OFF
      -DCPACK_GENERATOR=BREW
      -DENABLE_SYSTEM_PUGIXML=ON
      -DENABLE_SYSTEM_TBB=ON
      -DENABLE_SYSTEM_PROTOBUF=ON
      -DENABLE_SYSTEM_FLATBUFFERS=ON
      -DENABLE_SYSTEM_SNAPPY=ON
    ]

    openvino_binary_dir = "#{buildpath}/build"
    system "cmake", "-S", ".", "-B", openvino_binary_dir, *cmake_args
    system "cmake", "--build", openvino_binary_dir
    system "cmake", "--install", openvino_binary_dir

    # build & install python bindings
    cd "src/bindings/python/wheel" do
      ENV["OPENVINO_BINARY_DIR"] = openvino_binary_dir
      ENV["PY_PACKAGES_DIR"] = Language::Python.site_packages(python3)
      ENV["WHEEL_VERSION"] = version
      ENV["SKIP_RPATH"] = "1"
      ENV["PYTHON_EXTENSIONS_ONLY"] = "1"
      ENV["CPACK_GENERATOR"] = "BREW"

      system python3, *Language::Python.setup_install_args(prefix, python3)
    end
  end

  test do
    pkg_config_flags = shell_output("pkg-config --cflags --libs openvino").chomp.split

    (testpath/"openvino_available_devices.c").write <<~EOS
      #include <openvino/c/openvino.h>

      #define OV_CALL(statement) \
          if ((statement) != 0) \
              return 1;

      int main() {
          ov_core_t* core = NULL;
          char* ret = NULL;
          OV_CALL(ov_core_create(&core));
          OV_CALL(ov_core_get_property(core, "CPU", "AVAILABLE_DEVICES", &ret));
      #ifndef __APPLE__
          OV_CALL(ov_core_get_property(core, "GPU", "AVAILABLE_DEVICES", &ret));
      #endif
          OV_CALL(ov_core_get_property(core, "AUTO", "SUPPORTED_METRICS", &ret));
          OV_CALL(ov_core_get_property(core, "MULTI", "SUPPORTED_METRICS", &ret));
          OV_CALL(ov_core_get_property(core, "HETERO", "SUPPORTED_METRICS", &ret));
          OV_CALL(ov_core_get_property(core, "BATCH", "SUPPORTED_METRICS", &ret));
          ov_core_free(core);
          return 0;
      }
    EOS
    system ENV.cc, "#{testpath}/openvino_available_devices.c", *pkg_config_flags,
                   "-o", "#{testpath}/openvino_devices_test"
    system "#{testpath}/openvino_devices_test"

    (testpath/"openvino_available_frontends.cpp").write <<~EOS
      #include <openvino/frontend/manager.hpp>
      #include <iostream>

      int main() {
        std::cout << ov::frontend::FrontEndManager().get_available_front_ends().size();
        return 0;
      }
    EOS
    (testpath/"CMakeLists.txt").write <<~EOS
      cmake_minimum_required(VERSION 3.13)
      project(openvino_frontends_test)
      set(CMAKE_CXX_STANDARD 11)
      add_executable(${PROJECT_NAME} openvino_available_frontends.cpp)
      find_package(OpenVINO REQUIRED COMPONENTS Runtime ONNX TensorFlow TensorFlowLite Paddle PyTorch)
      target_link_libraries(${PROJECT_NAME} PRIVATE openvino::runtime)
    EOS

    system "cmake", testpath.to_s
    system "cmake", "--build", testpath.to_s
    assert_equal "6", shell_output("#{testpath}/openvino_frontends_test").strip

    system python3, "-c", <<~EOS
      import openvino.runtime as ov
      assert '#{version}' in ov.__version__
    EOS
  end
end
