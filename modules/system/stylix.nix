{ inputs, lib, ... }:
let
  inherit (lib)
    findFirst
    hasPrefix
    mkIf
    mkMerge
    mkOption
    optional
    types
    ;
in
{
  den.aspects.system._.stylix.homeManager =
    { config, ... }:
    let
      cacheHome =
        if config.xdg.enable then config.xdg.cacheHome else "${config.home.homeDirectory}/.cache";

      cfg = config.dotnix.stylix;

      wallpaperCacheFileDefault = "${cacheHome}/noctalia/wallpapers.json";
      fallbackWallpaper = inputs.noctalia + "/Assets/Wallpaper/noctalia.png";

      wallpaperCache =
        let
          parsed =
            if builtins.pathExists cfg.wallpaperCacheFile then
              builtins.tryEval (builtins.fromJSON (builtins.readFile cfg.wallpaperCacheFile))
            else
              {
                success = true;
                value = { };
              };
        in
        if parsed.success && builtins.isAttrs parsed.value then parsed.value else { };

      wallpaperCandidates =
        (builtins.attrValues (wallpaperCache.wallpapers or { }))
        ++ optional (wallpaperCache ? defaultWallpaper) wallpaperCache.defaultWallpaper;

      detectedWallpaper = findFirst (
        wallpaper:
        builtins.isString wallpaper && !hasPrefix "solid://" wallpaper && builtins.pathExists wallpaper
      ) null wallpaperCandidates;

      resolvedWallpaper =
        if detectedWallpaper != null then
          detectedWallpaper
        else if builtins.pathExists fallbackWallpaper then
          fallbackWallpaper
        else
          null;

      stylixImage =
        if cfg.wallpaper == null then
          null
        else if builtins.isPath cfg.wallpaper then
          cfg.wallpaper
        else if hasPrefix "/nix/store/" cfg.wallpaper then
          /. + builtins.unsafeDiscardStringContext cfg.wallpaper
        else
          /. + cfg.wallpaper;
    in
    {
      imports = [ inputs.stylix.homeModules.stylix ];

      options.dotnix.stylix = {
        wallpaperCacheFile = mkOption {
          type = types.str;
          default = wallpaperCacheFileDefault;
          description = "Path ke cache wallpaper Noctalia yang dipakai untuk auto-detect wallpaper aktif.";
        };

        wallpaper = mkOption {
          type = types.nullOr (
            types.oneOf [
              types.path
              types.str
            ]
          );
          default = resolvedWallpaper;
          example = "/home/seraphyne/Pictures/wallpapers/current.png";
          description = "Wallpaper yang dipakai Stylix. Default-nya diambil dari wallpaper aktif Noctalia.";
        };
      };

      config = mkMerge [
        {
          warnings =
            optional (detectedWallpaper == null && cfg.wallpaper == fallbackWallpaper) ''
              Stylix tidak bisa membaca wallpaper aktif dari ${cfg.wallpaperCacheFile} saat evaluasi flake,
              jadi sementara memakai fallback wallpaper bawaan Noctalia.
              Bila ingin membaca cache wallpaper Noctalia dari $HOME, build harus dijalankan dengan `--impure`.
              Set `dotnix.stylix.wallpaper` ke path yang stabil bila ingin warna mengikuti wallpaper tertentu.
              Perubahan wallpaper tetap butuh rebuild agar Stylix, Ghostty, dan btop ikut berubah.
            ''
            ++ optional (cfg.wallpaper == null) ''
              Stylix tidak diaktifkan karena tidak ada wallpaper valid yang bisa dipakai.
              Set `dotnix.stylix.wallpaper` secara manual bila perlu.
            '';
        }

        (mkIf (cfg.wallpaper != null) {
          stylix = {
            enable = true;
            autoEnable = false;
            image = stylixImage;
            polarity = "dark";
            opacity.terminal = 0.8;

            targets = {
              btop.enable = true;
              ghostty = {
                enable = true;
                fonts.enable = false;
              };
            };
          };
        })
      ];
    };
}
