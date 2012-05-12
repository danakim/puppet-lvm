#
# Define: lvm
#
# Defines a tool to create and manage logical volumes on a node.
#
# Include this function in the class to be applied to a collection of nodes,
# to make sure that every node gets the same LVM setup.
#
# Example:
# lvm { "/mysql":
#   lvsize  => '2G',
#   fstype  => 'xfs',
#   vgname  => 'vg00',
#   owner   => 'mysql',
#   group   => 'root',
#   mode    => '755'
# }
#

define lvm (
        $lvsize      = '1G',
        $fstype      = 'ext3',
        $options     = 'defaults',
        $vgname      = 'vg00',
        $lvname      = "${name}",
        $owner       = 'root',
        $group       = 'root',
        $mode        = '755'
 ) {
    if ( $fstype == 'xfs' ) {
        package { ['xfsprogs', 'xfsdump'] :
            ensure => installed
        }
    }

    file { "${name}":
        ensure => directory,
        owner  => $owner,
        group  => $group,
        mode   => $mode,
    }

    exec { "lvcreate-${vgname}-${lvname}":
        path      => [ '/sbin', '/bin', '/usr/sbin', '/usr/bin' ],
        logoutput => false,
        # Create and initialise the LV
        command   => "lvcreate -n ${lvname} -L ${lvsize} /dev/${vgname} && mkfs -t ${fstype} /dev/${vgname}/${lvname}",
        # Only if it does not exist already
        unless    => "lvs | grep -q '[[:space:]]${lvname}[[:space:]][[:space:]]*${vgname}[[:space:]]'",
        subscribe => File[ "$name" ],
    }

    mount { "${name}":
        atboot    => true,
        device    => "/dev/${vgname}/${lvname}",
        ensure    => mounted,
        fstype    => "${fstype}",
        options   => "${options}",
        dump      => '1',
        pass      => '2',
        require   => [ Exec[ "lvcreate-${vgname}-${lvname}" ], File[ "${name}" ] ],
    }

    # Avoid trying to define lvm2 twice which will happen if
    # we configure multiple logical volumes on the same node
    if ! defined( Package[ 'lvm2' ] ) {
        package { [ 'lvm2' ]:
            ensure => installed
        }
    }
}
