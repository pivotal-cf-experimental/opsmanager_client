# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require "httmultiparty"

module OpsmanagerClient
  class HTTPClient
    include HTTMultiParty
    read_timeout 300
    open_timeout 5

    def initialize(url, username, password)
      HTTPClient.base_uri(url)
      HTTPClient.basic_auth(username, password)
    end

    def installation
      ensure_successful(
        HTTPClient.get("/api/installation_settings", query)
      )
    end

    def delete_unused_products
      ensure_successful(
        HTTPClient.delete("/api/products", query)
      )
    end

    def available_products
      ensure_successful(
        HTTPClient.get("/api/products", query)
      )
    end

    def upload_product_from_file(product_file)
      retry_on_fail do
        ensure_successful(
          HTTPClient.post("/api/products", query(:product => {:file => product_file}))
        )
      end
    end

    def add_product(product)
      query_params = {
        'name' => product.name,
        'product_version' => product.version
      }
      ensure_successful(
        HTTPClient.post("/api/installation_settings/products", query(query_params))
      )
    end

    def remove_product_with_guid(guid)
      ensure_successful(
        HTTPClient.delete("/api/installation_settings/products/#{guid}", query)
      )
    end

    def upgrade_product(product, guid)
      query_params = {
        'to_version' => product.version
      }
      ensure_successful(
        HTTPClient.put("/api/installation_settings/products/#{guid}", query(query_params))
      )
    end

    def uninstall_product_with_guid(guid)
      ensure_successful(
        HTTPClient.delete("/api/installation_settings/products/#{guid}", query)
      )
    end

    def apply_changes
      response = ensure_successful(HTTPClient.post("/api/installation", query))
      task_id = response.fetch("install").fetch("id")
      task_id
    end

    private

    def retry_on_fail(max_attempts = 6, retryable_exceptions = [Net::ReadTimeout])
      attempts = 0
      begin
        attempts += 1
        yield
      rescue *retryable_exceptions
        if attempts < max_attempts
          puts "Attempt #{attempts}/#{max_attempts} failed. Retrying"
          retry
        end
        puts "All retries failed."
        raise
      end
    end

    def query(params = {})
      {
        :verify => false, # disable SSL verify
        :query => params
      }
    end

    def ensure_successful(http_response, permitted_status_codes=[200])
      if permitted_status_codes.include?(http_response.code)
        http_response
      else
        error_messages = http_response.fetch('errors'){ http_response.inspect }
        error_message  = Array(error_messages).join("\n")
        fail(error_message)
      end
    end
  end
end
