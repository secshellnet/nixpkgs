{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.aperisolve;
in
{
  options.services.aperisolve = {
    enable = lib.mkEnableOption "AperiSolve";

    package = lib.mkPackageOption pkgs "aperisolve";

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/aperisolve";
      description = ''
        Storage path of aperisolve.
      '';
    };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "[::1]";
      description = ''
        Address the server will listen on.
      '';
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = ''
        Port the server will listen on.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      ensureDatabases = [ "aperisolve" ];
      ensureUsers = [
        {
          name = "aperisolve";
          ensureDBOwnership = true;
        }
      ];
    };

    systemd.targets.aperisolve = {
      description = "Target for all AperiSolve services";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [
        "network-online.target"
        "redis-aperisolve.service"
      ];
    };

    systemd.services =
      let
        defaultServiceConfig = {
          WorkingDirectory = "${cfg.dataDir}";
          User = "aperisolve";
          Group = "aperisolve";
          StateDirectory = "aperisolve";
          StateDirectoryMode = "0750";
          Restart = "on-failure";
          RestartSec = 30;
        };
      in
      {
        aperisolve = {
          description = "AperiSolve WSGI Service";

          wantedBy = [ "aperisolve.target" ];

          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];

          environment.PYTHONPATH = cfg.package.pythonPath;

          serviceConfig = defaultServiceConfig // {
            ExecStart = ''
              ${cfg.package.gunicorn}/bin/gunicorn -w 4 -b ${cfg.listenAddress}:${toString cfg.port} aperisolve.wsgi:application
            '';
            PrivateTmp = true;
            TimeoutStartSec = lib.mkDefault "5min";
          };
        };

        netbox-rq = {
          description = "AperiSolve Request Queue Worker";

          wantedBy = [ "aperisolve.target" ];
          after = [ "aperisolve.service" ];

          environment.PYTHONPATH = cfg.package.pythonPath;

          serviceConfig = defaultServiceConfig // {
            ExecStart = ''
              ${config.package.pythonPath}/bin/aperisolve rq worker default --url redis://localhost:6379/0
            '';
            PrivateTmp = true;
          };
        };
      };

    users.users.aperisolve = {
      isSystemUser = true;
      group = "aperisolve";
    };
    users.groups.aperisolve = { };
    users.groups."${config.services.redis.servers.aperisolve.user}".members = [ "aperisolve" ];
  };
}
