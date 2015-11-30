# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

module OpsmanagerClient
  class Product
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def to_s
      "#{name} v#{version}"
    end

    def name
      filename_without_extension[/(p\-[a-z0-9]+)\-/i, 1]
    end

    def version
      filename_without_extension[/#{name}\-(.+)$/, 1]
    end

    def file
      File.open(path)
    end

    private

    def filename_without_extension
      File.basename(path, ".*")
    end
  end
end
