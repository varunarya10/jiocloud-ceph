# Fact: ceph_osd_bootstrap_key
#
# Purpose:
#
# Resolution:
#
# Caveats:
#

require 'facter'
require 'timeout'

timeout = 10

# ceph_osd_bootstrap_key
# Fact that gets the ceph key "client.bootstrap-osd"

Facter.add(:ceph_admin_key, :timeout => timeout) do
  if system("ceph -s > /dev/null 2>&1")
    setcode { Facter::Util::Resolution.exec("ceph auth get-key client.admin") }
  end
end

## blkid_uuid_#{device} / ceph_osd_id_#{device}
## Facts that export partitions uuids & ceph osd id of device

# Load the osds/uuids from ceph

begin
  Timeout::timeout(timeout) {
    if system("ceph -s > /dev/null 2>&1")
      ceph_osds = Hash.new
      ceph_osd_dump = Facter::Util::Resolution.exec("ceph osd dump")
      ceph_osd_dump and ceph_osd_dump.each_line do |line|
        if line =~ /^osd\.(\d+).* ([a-f0-9\-]+)$/
          ceph_osds[$2] = $1
        end
      end

      blkid = Facter::Util::Resolution.exec("blkid")
      blkid and blkid.each_line do |line|
        if line =~ /^\/dev\/(.+):.*UUID="([a-fA-F0-9\-]+)"/
          device = $1
          uuid = $2

          Facter.add("blkid_uuid_#{device}") { setcode { uuid } }
          Facter.add("ceph_osd_id_#{device}") { setcode { ceph_osds[uuid] } }
        end
      end
    end
  }
rescue Timeout::Error
  Facter.warnonce('ceph command timeout in ceph_osd_bootstrap_key fact')
end
