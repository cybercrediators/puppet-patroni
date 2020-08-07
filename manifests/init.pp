# Sets up and configures a Patroni instance
class patroni (

  # Global Settings
  String $scope,
  String $namespace,
  String $hostname,

  # Bootstrap Settings
  Integer $dcs_loop_wait,
  Integer $dcs_ttl,
  Integer $dcs_retry_timeout,
  Integer $dcs_maximum_lag_on_failover,
  Integer $dcs_master_start_timeout,
  Boolean $dcs_synchronous_mode,
  Boolean $dcs_synchronous_mode_strict,
  Boolean $dcs_postgresql_use_pg_rewind,
  Boolean $dcs_postgresql_use_slots,
  Hash $dcs_postgresql_recovery_conf,
  Hash $dcs_postgresql_parameters,
  String $bootstrap_method,
  Boolean $initdb_data_checksums,
  String $initdb_encoding,
  String $initdb_locale,
  Array[String] $bootstrap_pg_hba,
  Hash $bootstrap_users,
  Variant[Undef,String] $bootstrap_post_bootstrap,
  Variant[Undef,String] $bootstrap_post_init,

  # PostgreSQL Settings
  String $superuser_username,
  String $superuser_password,
  String $replication_username,
  String $replication_password,
  Variant[Undef,String] $callback_on_reload,
  Variant[Undef,String] $callback_on_restart,
  Variant[Undef,String] $callback_on_role_change,
  Variant[Undef,String] $callback_on_start,
  Variant[Undef,String] $callback_on_stop,
  String $pgsql_connect_address,
  Array[String] $pgsql_create_replica_methods,
  String $pgsql_data_dir,
  Variant[Undef,String] $pgsql_config_dir,
  Variant[Undef,String] $pgsql_bin_dir,
  String $pgsql_listen,
  Boolean $pgsql_use_unix_socket,
  String $pgsql_pgpass_path,
  Hash $pgsql_recovery_conf,
  Variant[Undef,String]  $pgsql_custom_conf,
  Hash $pgsql_parameters,
  Array[String] $pgsql_pg_hba,
  Integer $pgsql_pg_ctl_timeout,
  Boolean $pgsql_use_pg_rewind,
  Boolean $hiera_merge_pgsql_parameters,
  Boolean $pgsql_remove_data_directory_on_rewind_failure,
  Array[Hash] $pgsql_replica_method,

  # Tags
  Variant[Undef,Boolean] $tag_nofailover,
  Variant[Undef,Boolean] $tag_clonefrom,
  Variant[Undef,Boolean] $tag_noloadbalance,
  # IP address/hostname of another replica for cascading replication support
  Variant[Undef,String]  $tag_replicatefrom,
  Variant[Undef,Boolean] $tag_nosync,

  # Consul Settings
  Boolean $use_consul,
  String $consul_host,
  Variant[Undef,String] $consul_url,
  Integer $consul_port,
  Enum['http','https'] $consul_scheme,
  Variant[Undef,String] $consul_token,
  Boolean $consul_verify,
  Optional[Boolean] $consul_register_service,
  Optional[String] $consul_service_check_interval,
  Optional[Enum['default', 'consistent', 'stale']] $consul_consistency,
  Variant[Undef,String] $consul_cacert,
  Variant[Undef,String] $consul_cert,
  Variant[Undef,String] $consul_key,
  Variant[Undef,String] $consul_dc,
  Variant[Undef,String] $consul_checks,

  # Etcd Settings
  Boolean $use_etcd,
  String $etcd_host,
  Array[String] $etcd_hosts,
  Variant[Undef,String] $etcd_url,
  Variant[Undef,String] $etcd_proxyurl,
  Variant[Undef,String] $etcd_srv,
  Enum['http','https'] $etcd_protocol,
  Variant[Undef,String] $etcd_username,
  Variant[Undef,String] $etcd_password,
  Variant[Undef,String] $etcd_cacert,
  Variant[Undef,String] $etcd_cert,
  Variant[Undef,String] $etcd_key,

  # Exhibitor Settings
  Boolean $use_exhibitor,
  Array[String] $exhibitor_hosts,
  Integer $exhibitor_poll_interval,
  Integer $exhibitor_port,

  # Kubernetes Settings
  Boolean $use_kubernetes,
  String $kubernetes_namespace,
  Hash $kubernetes_labels,
  Variant[Undef,String] $kubernetes_scope_label,
  Variant[Undef,String] $kubernetes_role_label,
  Boolean $kubernetes_use_endpoints,
  Variant[Undef,String] $kubernetes_pod_ip,
  Variant[Undef,String] $kubernetes_ports,

  # REST API Settings
  String $restapi_connect_address,
  String $restapi_listen,
  Variant[Undef,String] $restapi_username,
  Variant[Undef,String] $restapi_password,
  Variant[Undef,String] $restapi_certfile,
  Variant[Undef,String] $restapi_keyfile,

  # ZooKeeper Settings
  Boolean $use_zookeeper,
  Array[String] $zookeeper_hosts,

  # Watchdog Settings
  Enum['off','automatic','required'] $watchdog_mode,
  String $watchdog_device,
  Integer $watchdog_safety_margin,

  # Module Specific Settings
  String $servicename,
  String $packagename,
  String $config_path,
  String $config_owner,
  String $config_group,
  String $config_mode,
  String $ensure_package,
  String $ensure_service,
  Boolean $enable_service,
  Boolean $restart_service,
  Optional[String] $restart_service_command,

) inherits patroni::params {

  if ! ($::osfamily in ["Debian", "RedHat"]) {
    fail("This operating system family (${::osfamily}) is not supported.")
  }

  if ! $pgsql_data_dir {
    warning("This operating system version (${::operatingsystemmajrelease}) is not supported. 'pgqsl_data_dir' variable must be specified manually.")
  }

  if $hiera_merge_pgsql_parameters == true {
    $pgsql_parameters_all = lookup( { 'name'          => 'patroni::pgsql_parameters',
                                      'value_type'    => undef,
                                      'merge'         => {
                                        'strategy'   => 'deep',
                                      },
                                      'default_value' => $pgsql_parameters,
                                    })
  } else {
    $pgsql_parameters_all = $pgsql_parameters
  }

  anchor{'patroni::begin':}
  -> class{'::patroni::install':}
  -> class{'::patroni::config':}

  if $restart_service {
    Class['::patroni::config']
    ~> class{'::patroni::service':}
  }
  else {
    Class['::patroni::config']
    -> class{'::patroni::service':}
  }

  Class['::patroni::service']
  -> anchor{'patroni::end':}
}
