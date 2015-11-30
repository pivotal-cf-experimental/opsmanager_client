# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require "opsmanager_client/client/version"
require "opsmanager_client/product"
require "opsmanager_client/http_client"

module OpsmanagerClient
  class Client

    module Internals
      class Job
        def initialize(opts={})
          @type       = opts.fetch('identifier')
          @guid       = opts.fetch('guid')
          @properties = Hash[opts.fetch('properties', {}).map{|property| [property.fetch('identifier'), property.fetch('value',nil)] }]
          @product    = opts.fetch('product')
          @partitions = opts.fetch('partitions', []).map{|p| JobPartition.new(p) }
        end

        attr_reader :type, :guid, :properties, :product, :partitions

        def ips
          product.ips.values_at(*partitions.map(&:guid)).flatten.compact.uniq
        end
      end

      class JobPartition
        def initialize(opts={})
          @guid                        = "#{opts.fetch('job_reference')}-partition-#{opts.fetch('availability_zone_reference')}"
          @installation_name           = opts.fetch('installation_name')
          @instance_count              = opts.fetch('instance_count')
          @availability_zone_reference = opts.fetch('availability_zone_reference')
        end

        attr_reader :guid, :installation_name, :instance_count, :availability_zone_reference
      end

      class Product
        def initialize(opts={})
          @jobs    = opts.fetch('jobs').map{|job_details| Internals::Job.new(job_details.merge('product' => self)) }
          @ips     = opts.fetch('ips', {})
          @type    = opts.fetch('identifier')
          @version = opts.fetch('product_version')
          @guid    = opts.fetch('guid')
          @prepared = opts.fetch('prepared')
        end

        attr_reader :jobs, :ips, :type, :version, :guid, :prepared

        def job_of_type(job_type)
          jobs.find { |job| job.type == job_type }
        end

        def has_job_of_type?(job_type)
          job_of_type(job_type) != nil
        end
      end
    end

    def initialize(url, username, password)
      @http_client = HTTPClient.new(url, username, password)
    end

    def upload_product(product)
      @http_client.upload_product_from_file(product.file) unless product_uploaded?(product)
    end

    def add_product(product)

      if product_added_or_installed?(product)
        return "Product #{product} has already been added to the installation"
      end

      @http_client.add_product(product)
    end

    def remove_product(product)

      if !product_added?(product)
        return "Product #{product} is not added to the installation"
      end

      guid = guid_for_currently_installed_product_of_type(product.name)
      @http_client.remove_product_with_guid(guid)
    end

    def cf_installed?
      !installed_products.find { |p| p.type == 'cf' }.nil?
    end

    def upgrade_product(product)
      if !product_uploaded?(product)
        raise "Unable to find available product"
      end

      if !different_version_installed?(product)
        raise "No product available to upgrade from"
      end

      guid = guid_for_currently_installed_product_of_type(product.name)
      @http_client.upgrade_product(product, guid)
    end

    def delete_unused_products
      @http_client.delete_unused_products
    end

    def available_products
      @http_client.available_products
    end

    def product_added_or_installed?(product)
      installed_or_configured_products.any? { |installed_product|
        installed_product.type == product.name &&
          installed_product.version == product.version
      }
    end

    def product_added?(product)
      installed_or_configured_products.any? { |installed_product|
        installed_product.type == product.name &&
          installed_product.version == product.version &&
            !installed_product.prepared
      }
    end

    def product_installed?(product)
      installed_or_configured_products.any? { |installed_product|
        installed_product.type == product.name &&
          installed_product.version == product.version &&
            installed_product.prepared
      }

    end

    def product_type_installed?(product)
      installed_or_configured_products.any? { |installed_product|
        installed_product.type == product.name
      }
    end

    def product_uploaded?(product)
      available_products.include?(
        "name" => product.name,
        "product_version" => product.version
      )
    end

    def uninstall_product_and_apply_changes(product_to_uninstall)
      installed_product = installed_or_configured_products.find { |product|
        product.type == product_to_uninstall.name
      }

      if installed_product
        @http_client.uninstall_product_with_guid(installed_product.guid)
        apply_changes
      else
        "Product not installed"
      end
    end

    def apply_changes
      @http_client.apply_changes
    end

    def cf_admin_credentials
      cf_admin = uaa_job.properties.fetch("admin_credentials")

      OpenStruct.new(
        :username => cf_admin.fetch("identity"),
        :password => cf_admin.fetch("password")
      )
    end

    def cf_admin_client_secret
      uaa_job.properties.fetch("admin_client_credentials").fetch("password")
    end

    def first_ip_of_product_job(product_name, job_type)
      product(product_name).job_of_type(job_type).ips.first
    end

    def system_domain
      product("cf").job_of_type('cloud_controller').properties.fetch("system_domain")
    end

    def cc_client_credentials
      OpenStruct.new(
        :identity => "cloud_controller", #Bug in POM means it reports wrong identity cc_client.fetch("identity"),
        :password => uaa_job.properties.fetch("cc_client_credentials").fetch("password")
      )
    end

    def vms_for_job_type(job_type)
      product = product_that_has_job_of_type(job_type)
      job = product.job_of_type(job_type)
      vm_credentials = job.properties.fetch('vm_credentials')

      job.ips.map { |ip|
        OpenStruct.new(
          :hostname => ip,
          :username => vm_credentials.fetch("identity"),
          :password => vm_credentials.fetch("password")
        )
      }
    end

    private

    def guid_for_currently_installed_product_of_type(type)
      installed_or_configured_products.find { |installed_product|
        installed_product.type == type
      }.guid
    end

    def different_version_installed?(product)
      installed_or_configured_products.select { |installed_product|
        installed_product.type == product.name && installed_product.version != product.version
      }.any?
    end

    def product_that_has_job_of_type(job_type)
      installed_or_configured_products.find { |product| product.has_job_of_type?(job_type) }
    end

    def installed_or_configured_products
      installation.fetch('products').map { |product_options| Internals::Product.new(product_options) }
    end

    def installed_products
      installed_or_configured_products.reject { |product| product.ips.empty? }
    end

    def installation
      @http_client.installation
    end

    def product(product_name)
      installed_or_configured_products.find { |product|
        product.type == product_name
      }
    end

    def uaa_job
      product("cf").job_of_type('uaa')
    end
  end
end
