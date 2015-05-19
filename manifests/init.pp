# -----------------------------------------------------------------------------
#   Copyright (c) 2012 Bryce Johnson
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
# -----------------------------------------------------------------------------
# == Class: jira
#
# This module is used to install Jira.
#
# See README.md for more details
# 
# === Authors
#
# Bryce Johnson
# Merritt Krakowitzer
#
# === Copyright
#
# Copyright (c) 2012 Bryce Johnson
#
# Published under the Apache License, Version 2.0
#
class jira (

  # Jira Settings
  $version      = '6.3.4a',
  $product      = 'jira',
  $format       = 'tar.gz',
  $installdir   = '/opt/jira',
  $homedir      = '/home/jira',
  $user         = 'jira',
  $group        = 'jira',
  $uid          = undef,
  $gid          = undef,

  # Database Settings
  $db           = 'postgresql',
  $dbuser       = 'jiraadm',
  $dbpassword   = 'mypassword',
  $dbserver     = 'localhost',
  $dbname       = 'jira',
  $dbport       = '5432',
  $dbdriver     = 'org.postgresql.Driver',
  $dbtype       = 'postgres72',
  $poolsize     = '20',

  # Configure database settings if you are pooling connections
  $enable_connection_pooling = false,
  $poolMinSize               = 20,
  $poolMaxSize               = 20,
  $poolMaxWait               = 30000,
  $validationQuery           = undef,
  $minEvictableIdleTime      = 60000,
  $timeBetweenEvictionRuns   = undef,
  $poolMaxIdle               = 20,
  $poolRemoveAbandoned       = true,
  $poolRemoveAbandonedTimout = 300,
  $poolTestWhileIdle         = true,
  $poolTestOnBorrow          = true,

  # JVM Settings
  $javahome,
  $jvm_xms      = '256m',
  $jvm_xmx      = '1024m',
  $jvm_permgen  = '256m',
  $jvm_optional = '-XX:-HeapDumpOnOutOfMemoryError',
  $java_opts    = '',

  # Misc Settings
  $downloadURL  = 'http://www.atlassian.com/software/jira/downloads/binary/',

  # Choose whether to use nanliu-staging, or mkrakowitzer-deploy
  # Defaults to nanliu-staging as it is puppetlabs approved.
  $staging_or_deploy = 'staging',

  # Choose whether to use $staging_or_deploy style deployment,
  # or using a rpm package for deployment.
  $deployment_type = 'download',
  $package_name = 'jira',
  $package_release_tag = undef,

  # Manage service
  $service_manage = true,
  $service_ensure = running,
  $service_enable = true,

  # Tomcat
  $tomcatPort = 8080,

  # Tomcat Tunables
  $tomcatMaxThreads  = '150',
  $tomcatAcceptCount = '100',
  
  # Reverse https proxy
  $proxy = {},

) {

  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }

  if $jira::db != 'postgresql' and $jira::db != 'mysql' {
    fail('jira db parameter must be postgresql or mysql')
  }

  if $::jira_version {
    # If the running version of JIRA is less than the expected version of JIRA
    # Shut it down in preparation for upgrade.
    if versioncmp($version, $::jira_version) > 0 {
      notify { 'Attempting to upgrade JIRA': }
      exec { 'service jira stop && sleep 15': before => Anchor['jira::start'] }
    }
  }

  $webappdir    = "${installdir}/atlassian-${product}-${version}-standalone"
  $dburl        = "jdbc:${db}://${dbserver}:${dbport}/${dbname}"

  anchor { 'jira::start':
  } ->
  class { 'jira::install':
  } ->
  class { 'jira::config':
  } ~>
  class { 'jira::service':
  } ->
  anchor { 'jira::end': }

}
