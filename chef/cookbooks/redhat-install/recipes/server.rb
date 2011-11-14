# Copyright 2011, Dell
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

admin_ip = Chef::Recipe::Barclamp::Inventory.get_network_by_type(node, "admin").address
domain_name = node[:dns].nil? ? node[:domain] : (node[:dns][:domain] || node[:domain])
web_port = node[:provisioner][:web_port]
use_local_security = node[:provisioner][:use_local_security]
os_token="#{node[:platform]}-#{node[:platform_version]}"

image="redhat_install"
rel_path= "#{os_token}/install/#{image}"
install_path = "/tftpboot/#{rel_path}"
pxecfg_path="/tftpboot/discovery/pxelinux.cfg"

admin_web="http://#{admin_ip}:#{web_port}/#{os_token}/install"
os_repo_web="#{admin_web}/Server"
crowbar_repo_web="#{admin_web}/crowbar-extras"
append_line="method=#{admin_web} ks=#{admin_web}/#{image}/compute.ks ksdevice=bootif initrd=../#{os_token}/install/images/pxeboot/initrd.img"

if node[:provisioner][:use_serial_console]
  append_line = "console=tty0 console=ttyS1,115200n8 " + append_line
end
if ::File.exists?("/etc/crowbar.install.key")
  append_line = "crowbar.install.key=#{::File.read("/etc/crowbar.install.key").chomp.strip} " + append_line
end

# Make sure the directories need to net_install are there.
directory "#{install_path}" do  
  recursive true  
end

template "#{install_path}/compute.ks" do
  mode 0644
  source "compute.ks.erb"
  owner "root"
  group "root"
  variables(
            :admin_node_ip => admin_ip,
            :web_port => web_port,
            :os_repo => os_repo_web,
            :crowbar_repo => crowbar_repo_web)  
end

template "#{pxecfg_path}/#{image}" do
  mode 0644
  owner "root"
  group "root"
  source "default.erb"
  variables(:append_line => "append " + append_line,
            :install_name => image,  
            :kernel => "../#{os_token}/install/images/pxeboot/vmlinuz")
end

template "#{install_path}/crowbar_join.sh" do
  mode 0644
  owner "root"
  group "root"
  source "crowbar_join.sh.erb"
  variables(:admin_ip => admin_ip)
end
