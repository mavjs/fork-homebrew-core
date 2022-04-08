class Pgrouting < Formula
  desc "Provides geospatial routing for PostGIS/PostgreSQL database"
  homepage "https://pgrouting.org/"
  url "https://github.com/pgRouting/pgrouting/releases/download/v3.3.1/pgrouting-3.3.1.tar.gz"
  sha256 "70b97a7abab1813984706dffafe29aeb3ad98fbe160fda074fd792590db106b6"
  license "GPL-2.0-or-later"
  head "https://github.com/pgRouting/pgrouting.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_monterey: "0d9d7911e147f78b491d68300fa942d7937de612ff3098665fa7490c943099bd"
    sha256 cellar: :any_skip_relocation, arm64_big_sur:  "4e0ebfc58d08e965ad5e726f850151dd91838224671936e946d046ffe2db2101"
    sha256 cellar: :any_skip_relocation, monterey:       "d0776935c96441cf3467b1b522760de5e617496e3cee0abab89981f125ed573d"
    sha256 cellar: :any_skip_relocation, big_sur:        "8160f9e8421d16996fe418bf82637acc0cf9eafe72a6e482df8dca5e41feb404"
    sha256 cellar: :any_skip_relocation, catalina:       "e649753bce351dde13226665c14f5260302d3fd010880f52c2783133f0144974"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "b8a0b7441ae375712bc920e8ee37cb11692613ba897ded8e54fae2bcfd04fd00"
  end

  depends_on "cmake" => :build
  depends_on "boost"
  depends_on "cgal"
  depends_on "gmp"
  depends_on "libpq"
  depends_on "postgis"

  def install
    mkdir "stage"
    mkdir "build" do
      system "cmake", "-DWITH_DD=ON", "..", *std_cmake_args
      system "make"
      system "make", "install", "DESTDIR=#{buildpath}/stage"
    end

    libpq_prefix = Formula["libpq"].prefix.realpath
    libpq_stage_path = File.join("stage", libpq_prefix)
    share.install (buildpath/libpq_stage_path/"share").children

    libpq_opt_prefix = Formula["libpq"].prefix
    libpq_opt_stage_path = File.join("stage", libpq_opt_prefix)
    lib.install (buildpath/libpq_opt_stage_path/"lib").children

    # write the postgres version in the install to ensure rebuilds on new major versions
    inreplace share/"postgresql/extension/pgrouting.control",
      "# pgRouting Extension",
      "# pgRouting Extension for PostgreSQL #{Formula["postgresql"].version.major}"
  end

  test do
    expected = "for PostgreSQL #{Formula["postgresql"].version.major}"
    assert_match expected, (share/"postgresql/extension/pgrouting.control").read
  end
end
