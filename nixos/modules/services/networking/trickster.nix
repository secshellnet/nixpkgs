{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.trickster;
in
{
  imports = [
    (mkRenamedOptionModule [ "services" "trickster" "origin" ] [ "services" "trickster" "origin-url" ])
  ];

  options = {
    services.trickster = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable Trickster.
        '';
      };

      package = mkPackageOption pkgs "trickster" { };

      configFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          Path to configuration file.
        '';
      };

      instance-id = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = ''
          Instance ID for when running multiple processes (default null).
        '';
      };

      log-level = mkOption {
        type = types.str;
        default = "info";
        description = ''
          Level of Logging to use (debug, info, warn, error) (default "info").
        '';
      };

      metrics-port = mkOption {
        type = types.port;
        default = 8082;
        description = ''
          Port that the /metrics endpoint will listen on.
        '';
      };

      origin-type = mkOption {
        type = types.enum [
          "prometheus"
          "influxdb"
        ];
        default = "prometheus";
        description = ''
          Type of origin (prometheus, influxdb)
        '';
      };

      origin-url = mkOption {
        type = types.str;
        default = "http://prometheus:9090";
        description = ''
          URL to the Origin. Enter it like you would in grafana, e.g., http://prometheus:9090 (default http://prometheus:9090).
        '';
      };

      profiler-port = mkOption {
        type = types.nullOr types.port;
        default = null;
        description = ''
          Port that the /debug/pprof endpoint will listen on.
        '';
      };

      proxy-port = mkOption {
        type = types.port;
        default = 9090;
        description = ''
          Port that the Proxy server will listen on.
        '';
      };

    };
  };

  config = mkIf cfg.enable {
    systemd.services.trickster = {
      description = "Reverse proxy cache and time series dashboard accelerator";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        DynamicUser = true;
        ExecStart = ''
          ${cfg.package}/bin/trickster \
          -log-level ${cfg.log-level} \
          -metrics-port ${toString cfg.metrics-port} \
          -origin-type ${cfg.origin-type} \
          -origin-url ${cfg.origin-url} \
          -proxy-port ${toString cfg.proxy-port} \
          ${optionalString (cfg.configFile != null) "-config ${cfg.configFile}"} \
          ${optionalString (cfg.profiler-port != null) "-profiler-port ${cfg.profiler-port}"} \
          ${optionalString (cfg.instance-id != null) "-instance-id ${cfg.instance-id}"}
        '';
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        Restart = "always";
      };
    };
  };

  meta.maintainers = with maintainers; [ _1000101 ];

}
