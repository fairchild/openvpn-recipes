#
# Cookbook Name:: openvpn
# Recipe:: default
#
# 
# Copyright 2009, James Golick
#
# Distributable under the terms of the MIT license.
#

package "openvpn" do
  action :install
end

service "openvpn" do
  supports :restart => true
  action :enable
end

package "bridge-utils" do
  action :install
end

execute "Add br interface" do
  line = "auto lo br0"
  command "echo '#{line}' >> /etc/network/interfaces && /etc/init.d/networking restart"
  not_if  "cat /etc/network/interfaces | grep -q '#{line}'"
end

directory "/etc/openvpn/easy-rsa" do
  action :create
  owner  "root"
  group  "admin"
end

execute "copy easy-rsa files" do
  command "cp -R /usr/share/doc/openvpn/examples/easy-rsa/2.0/* /etc/openvpn/easy-rsa"
  not_if  "test -f /etc/openvpn/easy-rsa/openssl.cnf"
end

template "/etc/openvpn/easy-rsa/vars" do
  source "vars.erb"
  mode   0755
end

template "/etc/openvpn/easy-rsa/create-server-ca" do
  source "create-server-ca.erb"
  mode   0755
end

execute "setup server CA" do
  command "/etc/openvpn/easy-rsa/create-server-ca"
  creates "/etc/openvpn/server.crt"
end

template "/etc/openvpn/up.sh" do
  source "up.sh.erb"
  mode 0755
end

template "/etc/openvpn/down.sh" do
  source "down.sh.erb"
  mode 0755
end

execute "setup ip_forwarding" do
  command "echo 1 > /proc/sys/net/ipv4/ip_forward"
  not_if  "cat /proc/sys/net/ipv4/ip_forward | grep -q 1"
end

template "/etc/openvpn/server.conf" do
  source "server.conf.erb"
  mode 0755
  notifies :restart, resources(:service => "openvpn")
end

template "/etc/openvpn/client.conf" do
  source "client.conf.erb"
end

template "/etc/openvpn/easy-rsa/make_client_package" do
  source "make_client_package.erb"
  mode 0755
end

service "openvpn" do
  supports :restart => true
  action :start
end

