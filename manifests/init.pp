# == Class: hostname
#
# This class manage entry in /etc/hosts and set machine's hostname
#
# Tow lines will be inserted:
# 127.0.0.1 fqdn hostname localhost
# $ip hostname (this line is needed to make working hostbased authentication)
class hostname {

  $hostnamefile = "/etc/hostname"
  $hostsfile    = "/etc/hosts"
  $shortname = inline_template("<%= clientcert.split('.').at(0) %>")

  file { $hostnamefile:
    ensure  => present,
    mode    => 664,
    owner   => root,
    group   => admin,
    content => "${shortname}\n",
    before  => Exec["sethostname"]
  }



  #questa parte di codice viene eseguita solo sugli host su aws
  if $ec2_hostname != undef {

    exec { "config-${hostsfile}":
      command => "/bin/sed -e '0,/127\\.0\\.0\\.1/{s/127\\.0\\.0\\.1.*/127.0.0.1 ${clientcert} ${shortname} localhost.localdomain localhost/g}' -i.bak ${hostsfile}",
      unless  => "/bin/grep '127.0.0.1 ${clientcert} ${shortname} localhost.localdomain localhost' ${hostsfile}",
      before  => Exec["sethostname"],
    }
  }

  exec { 'sethostname':
    command =>  $lsbdistcodename? {
      'hardy' => "/bin/hostname -F ${hostnamefile} && /etc/init.d/hostname.sh start && /bin/true",
      default => "/bin/hostname -F ${hostnamefile} && /etc/init.d/hostname start",
    },
    onlyif  => [ "/usr/bin/test \"`cat ${hostnamefile}`\" != \"${hostname}\"" ],
  }

  #443 trac
  exec { "refresh-kernel-hostname":
    command     => "/sbin/sysctl kernel.hostname=$(hostname)",
    unless      => "/usr/bin/test \"`sysctl kernel.hostname | awk '{print \$3}'`\" = \"`cat /etc/hostname`\"",
    subscribe   => Exec["sethostname"],
    require     => File["${hostnamefile}"],
  }

}
