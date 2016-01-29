class packer::vmtools inherits packer::vmtools::params {

  if $required_packages {
    package { $required_packages:
      ensure => installed,
    }
  }

  if $tools_iso {
    file { '/tmp/vmtools':
      ensure => directory,
    }

    # Do it with collectors in case $required_packages was empty
    Package <| |> -> File <| title == '/tmp/vmtools' |>

    mount { '/tmp/vmtools':
      ensure  => mounted,
      device  => "${root_home}/${tools_iso}",
      fstype  => 'iso9660',
      options => 'ro,loop',
      require => File[ '/tmp/vmtools' ],
    }

    exec { 'install vmtools':
      command => $install_cmd,
      path    => [ '/bin', '/usr/bin', ],
      require => Mount[ '/tmp/vmtools' ],
    }

    exec { 'remove /tmp/vmtools':
      command => 'umount /tmp/vmtools ; rmdir /tmp/vmtools',
      path    => [ '/bin', '/usr/bin', ],
      onlyif  => 'test -d /tmp/vmtools',
      require => Exec[ 'install vmtools' ],
    }

    case $::operatingsystemrelease {

      default: {
        file { "${root_home}/${tools_iso}":
          ensure  => absent,
          require => Exec[ 'remove /tmp/vmtools' ],
        }
      }
    }

    file_line { "remove /etc/fstab /tmp/vmtools":
      path    => '/etc/fstab',
      line    => '#/tmp/vmtools removed',
      match   => '/tmp/vmtools',
      require => Exec[ 'remove /tmp/vmtools' ],
    }
  }
}
