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
require "opsmanager_client/client"

# Before running these tests, when generating new cassettes, ensure you add
# a redis product to OpsMan with the version mentioned below in :product
module OpsmanagerClient
  describe Client, vcr: { record: :once } do
    let(:domain) { "doppio.london.cf-app.com" }
    let(:opsmanager_url) { "https://pcf.#{domain}" }
    let(:product) { OpenStruct.new(:name => "p-datadog-firehose-nozzle", :version => "0.0.1.alpha.7.c98a3b7.dirty") }
    let(:unavailable_product) { OpenStruct.new(:name => "p-notavailable" , :version => "1.3.212.0") }
    let(:microbosh_version) { "1.6.0.0" }
    let(:cf_version) { "1.6.0-build.315" }
    let(:cf_admin_password) { "cf_admin_password" }
    let(:cf_admin_client_secret) { "cf_admin_client_secret" }
    let(:cc_client_password) { "cc_client_password" }
    let(:router_vm_ip) { "10.0.16.15" }
    let(:router_vm_password) { "router_vm_password" }
    let(:opentsdb_firehose_nozzle_password) { "opentsdb_firehose_nozzle_password" }

    subject(:client) { Client.new(opsmanager_url, "admin", "password") }

    describe "#cf_admin_credentials" do
      it "admin username and password" do
        credentials = client.cf_admin_credentials
        expect(credentials.username).to eql("admin")
        expect(credentials.password).to eql(cf_admin_password)
      end
    end

    describe "#cf_admin_client_secret" do
      it "admin client secret" do
        expect(client.cf_admin_client_secret).to eql(cf_admin_client_secret)
      end
    end

    describe "#upload_product" do
      it "uploads product" do
        # Not testing this as we would need to have access to a product file
        # to upload. Leaving this for another time.
      end
    end

    describe "#product_uploaded?" do
      it "checks if a specific version of a product has been uploaded" do
        expect(client.product_uploaded?(product)).to be_truthy
      end
    end

    describe "#add_product" do
      context "when the product is available but not added" do
        before do
          expect(client.product_uploaded?(product)).to be_truthy
          expect(client.product_added_or_installed?(product)).to be_falsey
        end

        after do
          client.remove_product(product)
        end

        it "adds the product" do
          client.add_product(product)
          expect(client.product_added?(product)).to be_truthy
        end
      end

      context "when the product has already been added" do
        before do
          client.add_product(product)
          expect(client.product_added?(product)).to be_truthy
          expect(client.product_installed?(product)).to be_falsey
        end

        after do
          client.remove_product(product)
        end

        it "ignores the addition" do
          expect(client.add_product(product).to_s).to match(/.*has already been added to the installation/)
        end
      end

      context "when the product is not available" do
        it "returns some appropriate error" do
          expect { client.add_product(unavailable_product) }.to raise_error(/.*Unable to find available product.*/)
        end
      end
    end

    describe "#remove_product" do
      context "when the product is added" do
        before do
          client.add_product(product)
        end

        it "removes the product from the installation" do
          expect(client.product_added?(product)).to be_truthy
          client.remove_product(product)
          expect(client.product_added?(product)).to be_falsey
        end
      end

      context "when the product is not added" do
        it "should ignore the removal" do
          expect(client.remove_product(product).to_s).to match(/.*is not added to the installation/)
        end
      end
    end

    describe "#available_products" do
      it "lists available products" do
        expect(client.available_products).to include(
          {"name"=>"cf", "product_version"=>cf_version},
          {"name"=>"p-bosh", "product_version"=>microbosh_version}
        )
      end
    end

    describe "#uninstall_product_and_apply_changes" do
      context "when product is not installed" do
        before do
          expect(client.product_installed?(unavailable_product)).to be_falsey
        end

        it "ignores the uninstall" do
          expect(client.uninstall_product_and_apply_changes(unavailable_product).to_s).to eql("Product not installed")
        end
      end
    end

    describe "#system_domain" do
      it "returns the system domain" do
        expect(client.system_domain).to eql(domain)
      end
    end

    describe "#cf_uaa_credentials" do
     it "returns the uaa admin credentials" do
       credentials = client.cf_uaa_credentials("admin_credentials")
       expect(credentials.username).to eql("admin")
       expect(credentials.password).to eql(cf_admin_password)
     end

     it "returns the uaa opentsdb nozzle credentials" do
       credentials = client.cf_uaa_credentials("opentsdb_nozzle_credentials")
       expect(credentials.username).to eql("opentsdb-firehose-nozzle")
       expect(credentials.password).to eql(opentsdb_firehose_nozzle_password)
     end
    end

    describe "#cc_client_credentials" do
      it "returns the cloud controller client credentials" do
        credentials = client.cc_client_credentials
        expect(credentials.identity).to eql("cloud_controller")
        expect(credentials.password).to eql(cc_client_password)
      end
    end

    describe "#first_ip_of_product_job" do
      it "returns the first IP of a job in the given product" do
        ip = client.first_ip_of_product_job("cf", "router")
        expect(ip).to eql(router_vm_ip)
      end
    end

    describe "#vms_for_job_type" do
      it "lists the hosts" do
        expect(
          client.vms_for_job_type("router")
        ).to eql(
          [
            OpenStruct.new(:hostname => router_vm_ip, :username => "vcap", "password" => router_vm_password)
          ]
        )
      end
    end
  end
end
