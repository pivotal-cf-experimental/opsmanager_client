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

require "net/http"
require 'tempfile'
require "httmultiparty"

require "opsmanager_client/http_client"

def suppress_output(&block)
  orig_stderr = $stderr
  orig_stdout = $stdout
  $stderr = File.new('/dev/null', 'w')
  $stdout = File.new('/dev/null', 'w')

  yield

  $stdout = orig_stdout
  $stderr = orig_stderr
end

module OpsmanagerClient
  describe HTTPClient do
    describe "#upload_product_from_file" do
      let(:file) { Tempfile.new('foo') }
      let(:success_response) { double(:response, code: 200) }

      subject(:client) {
        HTTPClient.new("http://example.com", "user", "password")
      }

      # This is unit tested because it is not able to be tested at the level
      # above.
      it "uploads a file" do
        expect(HTTPClient).to receive(:post).with("/api/products", {
          verify: false,
          query: {
            product: {
              file: file
              }
            }
          }
        ).and_return(success_response)

        subject.upload_product_from_file(file)
      end

      it "retries when an upload fails" do
        attempts = 0

        expect(HTTPClient).to receive(:post) do
          attempts += 1
          raise Net::ReadTimeout if attempts == 1
          success_response
        end.twice

        suppress_output do
          expect {
            subject.upload_product_from_file(file)
          }.to_not raise_error
        end
      end

      it "only retries six times before giving up and returning the error" do
        expect(HTTPClient).to receive(:post).exactly(6).times.and_raise(Net::ReadTimeout)

        suppress_output do
          expect {
            subject.upload_product_from_file(file)
          }.to raise_error(Net::ReadTimeout)
        end
      end
    end
  end
end
