require 'activesupport'

set :server_address,    "integrity.giraffesoftlabs.com"
role :host,             server_address

set :user,                     "james"
set :cookbook_path,            "/var/chef/cookbooks"
set :cookbooks_archive,        "/home/#{user}/cookbooks.tar.gz"
set :cookbook_staging_path,    "/home/#{user}/cookbooks"
set :json_staging_path,        "/home/#{user}/dna.json"
set :chef_bin,                 "/usr/bin/chef-solo"
set :path_to_dna,              "/etc/chef/dna.json"
set :chef_config_staging_path, "/home/#{user}/solo.rb"
set :chef_config_path,         "/etc/chef/solo.rb"

set :cookbooks,             %w( openvpn )

set :country,  "CA" # MUST BE TWO CHARS
set :province, "Quebec"
set :city,     "Montreal"
set :company,  "Nine Lives"
set :email,    "jamesgolick@gmail.com"

task :sync_cookbooks do
  ensure_build_dir_exists
  sudo "mkdir -p #{cookbook_path}"
  `tar --file=build/cookbooks.tar.gz -czv cookbooks`
  put  File.read("build/cookbooks.tar.gz"), cookbooks_archive
  sudo "rm -Rf #{cookbook_staging_path}"
  run  "tar zxvf #{cookbooks_archive}"
  sudo "cp -R #{cookbook_staging_path} /var/chef"
end

task :write_json do
  dna = {
    :host => server_address,
    :recipes => cookbooks,
    :ca_country => country,
    :ca_province => province,
    :ca_city => city,
    :ca_company => company,
    :ca_email => email,
    :user  => user
  }
  sudo "mkdir -p /etc/chef"
  put dna.to_json, json_staging_path
  sudo "mv #{json_staging_path} #{path_to_dna}"
end

task :write_chef_config do
  str =<<-END
cookbook_path    "/var/chef/cookbooks"
log_level         :info
file_store_path  "/var/chef"
file_cache_path  "/var/chef"
Chef::Log::Formatter.show_time = false
  END
  put str, chef_config_staging_path
  sudo "mv #{chef_config_staging_path} #{chef_config_path}"
end

task :run_chef do
  sudo "#{chef_bin} -j #{path_to_dna}"
end

task :bootstrap do
  sudo "test -f #{chef_bin} || sudo gem install chef --source http://gems.rubyforge.org --source http://gems.opscode.com"
end

before :run_chef, :bootstrap, :sync_cookbooks, :write_json, :write_chef_config

task :generate_client_package do
  ensure_build_dir_exists
  sudo "/etc/openvpn/easy-rsa/make_client_package"
  get "/home/#{user}/client.tar.gz", "build/client.tar.gz"
end

def ensure_build_dir_exists
  FileUtils.mkdir_p "build"
end

