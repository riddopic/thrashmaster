# encoding: UTF-8
#
# Author:    Stefano Harding <riddopic@gmail.com>
# License:   Apache License, Version 2.0
# Copyright: (C) 2014-2015 Stefano Harding
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'certificate_authority'
require 'fileutils'

module ACME
  # Generates necessary certificates for Docker TLS Auth.
  #
  class Certs
    # Methods are also available as module-level methods as well as a mixin.
    extend self

    def gencerts(domain, cert_path)
      root   = certificate_authority(domain, cert_path)
      server = server_certificate(root, domain)
      client = client_certificate(root, domain)

      [ # You can reuse this file to generate more certs
        ['ca/key.pem',  root.key_material.private_key],
        ['ca/cert.pem', root.to_pem],

        # Those are default filenames expected by Docker
        ['ca.pem',   root.to_pem],
        ['key.pem',  client.key_material.private_key],
        ['cert.pem', client.to_pem],

        # Those files are supposed to be uploaded to server
        ["#{domain}/ca.pem",   root.to_pem],
        ["#{domain}/key.pem",  server.key_material.private_key],
        ["#{domain}/cert.pem", server.to_pem]
      ].each do |name, contents|
        path = File.join(cert_path, name)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, contents)
        File.chmod(0600, path)
      end

      puts "CA certificates are in #{$certs_path}/ca"
      puts "Client certificates are in #{$certs_path}"
      puts "Server certificates are in #{$certs_path}/#{$domain}"
    end

    def certificate_authority(domain, cert_path)
      cert_path = File.join(cert_path, 'ca', 'cert.pem')
      ca_path = File.join(cert_path, 'ca', 'key.pem')

      key_material = if File.exist?(ca_path)
        key = OpenSSL::PKey::RSA.new(File.read(ca_path))
        mem_key = CertificateAuthority::MemoryKeyMaterial.new
        mem_key.public_key = key.public_key
        mem_key.private_key = key
        mem_key
      else
        mem_key = CertificateAuthority::MemoryKeyMaterial.new
        mem_key.generate_key
        mem_key
      end

      if File.exist?(cert_path)
        raw_cert = File.read(cert_path)
        openssl = OpenSSL::X509::Certificate.new(raw_cert)
        cert = CertificateAuthority::Certificate.from_openssl(openssl)
        cert.key_material = key_material
        cert
      else
        root = CertificateAuthority::Certificate.new
        root.subject.common_name = domain
        root.serial_number.number = 1
        root.signing_entity = true
        root.key_material = key_material

        ca_profile = {
          "extensions" => {
            "keyUsage" => {
              "usage" => [ "critical", "keyCertSign" ]
            }
          }
        }

        root.sign!(ca_profile)
        root
      end
    end

    def server_certificate(root, domain)
      server = CertificateAuthority::Certificate.new
      server.subject.common_name = domain
      server.serial_number.number = rand(3..100000)
      server.parent = root
      server.key_material.generate_key
      server.sign!
      server
    end

    def client_certificate(root)
      client = CertificateAuthority::Certificate.new
      client.subject.common_name = domain
      client.serial_number.number = 2
      client.parent = root

      client.key_material.generate_key

      signing_profile = {
        "extensions" => {
          "extendedKeyUsage" => {
            "usage" => [ "clientAuth" ]
          }
        }
      }

      client.sign!(signing_profile)
      client
    end
  end
end
