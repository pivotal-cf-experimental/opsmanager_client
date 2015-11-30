# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require "spec_helper"
require "opsmanager_client/product"

module OpsmanagerClient
  describe Product do
    describe "#name" do
      it "extracts product name from file path" do
        with_product_file("p-cassandra-1.2.0.0.pivotal") do |file_path|
          expect(Product.new(file_path).name).to eql("p-cassandra")
        end
      end
    end

    describe "#version" do
      it "extracts product version from file path" do
        with_product_file("p-cassandra-1.2.0.0.pivotal") do |file_path|
          expect(Product.new(file_path).version).to eql("1.2.0.0")
        end
      end

      context "when using the vara pre-release versioning" do
        it "extracts product version from file path" do
          with_product_file("p-redis-1.3.0.0.alpha.95.sha1.pivotal") do |file_path|
            expect(Product.new(file_path).version).to eql("1.3.0.0.alpha.95.sha1")
          end
        end
      end
    end

    describe "#file" do
      it "can access the file on disk" do
        with_product_file(:name => "p-cassandra", :version => "1.0.0") do |file_path|
          expect(Product.new(file_path).file.read).to eql("")
        end
      end
    end

    describe "#to_s" do
      it "returns a user-friendly product name and version" do
        with_product_file("p-cassandra-1.2.0.0.pivotal") do |file_path|
          expect(Product.new(file_path).to_s).to eql("p-cassandra v1.2.0.0")
        end
      end
    end

    def with_product_file(filename)
      file_path = File.expand_path("../#{filename}")
      FileUtils.touch(file_path)

      yield file_path
    ensure
      FileUtils.rm(file_path)
    end
  end
end
