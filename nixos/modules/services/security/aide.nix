{ config
, lib
, pkgs
, ...
}: let
  cfg = config.services.aide;
  configFile = pkgs.writeText "aide.conf" ''
    # The location of the database
    database_in=${cfg.database_url}

    # The location of the log file
    report_url=file:/var/log/aide/aide.log

    # Directories to be checked
    ${lib.concatStringsSep "\n" (map (dir: "${dir} R")
    cfg.directories)}

    # Files to be checked
    ${lib.concatStringsSep "\n" (map (file: "${file} R")
    cfg.files)}
  '';
  inherit (lib) mkEnableOption mkOption types mkIf;
in {
  options = {
    services.aide = {
      enable = mkEnableOption "AIDE file integrity checker";

      interval = mkOption {
        type = types.str;
        default = "*-*-* 04:00:00";
        description = ''
          How often aide is invoked. See systemd.time(7) for more
          information about the format.
        '';
      };

      database_url = mkOption {
        type = types.str;
        description = "Database URL.";
        default = "file:/var/lib/aide/aide.db";
        example = "file:/var/lib/aide/aide.db";
      };

      directories = mkOption {
        type = with types; listOf str;
        description = ''
          list of directories to be checked by aide
        '';
        default = [
          "/etc"
          "/bin"
          "/usr"
          "/var"
          "/home"
        ];
      };

      files = mkOption {
        type = with types; listOf str;
        description = ''
          list of files to be checked by aide
        '';
        default = [
          "/etc/passwd"
          "/etc/shadow"
          "/etc/group"
          "/etc/hosts"
          "/etc/hostname"
          "/etc/resolv.conf"
          "/etc/fstab"
          "/etc/ssh/sshd_config"
          "/etc/ssh/ssh_config"
          "/etc/ssh/ssh_host_rsa_key"
          "/etc/ssh/ssh_host_dsa_key"
          "/etc/ssh/ssh_host_ecdsa_key"
        ];
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.aide ];

    systemd.services.aide-init = {
      wantedBy = [ "multi-user.target" ];
      # if the sqlite file can be found assume the database has already been initialised
      script = ''
        db_url="${cfg.database_url}"
        db_path="''${db_url#file:}"
        if [ ! -f "$db_path" ]; then
          ${pkgs.aide}/bin/aide --config=${configFile} --init
        fi
      '';
      serviceConfig = {
        Type = "oneshot";
        StateDirectory = "aide";
        LogsDirectory = "aide";
        PrivateTmp = "yes";
        PrivateDevices = "yes";
        DynamicUser = true;
        ReadOnlyPaths = cfg.directories ++ cfg.files;
      };
    };

    systemd.timers.aide = {
      description = "Timer for AIDE file integrity checker";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.interval;
        Unit = "aide.service";
      };
    };

    systemd.services.aide = {
      description = "Advanced Intrusion Detection Environment file integrity checker";
      after = [ "aide-init.service" ];
      restartTriggers = [ configFile ];

      serviceConfig = {
        ExecStart = "${pkgs.aide}/bin/aide --config=${configFile} --check";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        DynamicUser = true;
        StateDirectory = "aide";
        LogsDirectory = "aide";
        PrivateTmp = "yes";
        PrivateDevices = "yes";
        PrivateNetwork = "yes";
        ReadOnlyPaths = cfg.directories ++ cfg.files;
      };
    };
  };
}
