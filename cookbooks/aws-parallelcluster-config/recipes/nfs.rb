# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: nfs
#
# Copyright:: 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# For performance, set NFS threads to max(num_cores, 8)
# This change will not be effective on Ubuntu1604 unless instance is restarted
# Changing thread in /etc/default/nfs-kernel-server and restarting NFS server will not change nfsd settings for Ubuntu1604
# See: https://ubuntuforums.org/showthread.php?t=2345636
# NFS threads enhancement is omitted for Ubuntu1604
node.force_override['nfs']['threads'] = [node['cpu']['cores'].to_i, 8].max

if platform?('ubuntu') && node['platform_version'].to_f >= 16.04
  # FIXME: https://github.com/atomic-penguin/cookbook-nfs/issues/93
  include_recipe "nfs::server"
end
include_recipe "nfs::server4"

if node['conditions']['overwrite_nfs_template']
  edit_resource(:template, node['nfs']['config']['server_template']) do
    source 'nfs/nfs.conf.erb'
    cookbook 'aws-parallelcluster-config'
  end
end

# Explicitly restart NFS server for thread setting to take effect
service node['nfs']['service']['server'] do
  action :restart
  supports restart: true
end
