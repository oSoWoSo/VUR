═══════════════════════════════════════════════════════════════
  Noctalia Shell installed successfully!
═══════════════════════════════════════════════════════════════

To initialize your configuration:

  $ noctalia-shell          # Symlink (recommended - auto-updates)
  $ noctalia-shell --copy   # Copy files (manual updates)
  $ noctalia-shell --force  # Force overwrite existing config

Configuration:
  System: /usr/share/quickshell/noctalia-shell
  User:   ~/.config/quickshell/noctalia-shell
  Cache:  ~/.cache/noctalia/

Optional dependencies for full functionality:

  cliphist                   clipboard history support
  matugen                    Material You color scheme generation
  (matugen Not in Void repos yet, trying wpgtk)
  cava                       audio visualizer component
  wlsunset                   night light functionality
  power-profiles-daemon      power profile management
  ddcutil                    external display brightness control
  xdg-desktop-portal         screen recorder portal option
  python3                    calendar events support
  evolution-data-server      calendar events support

  polkit-kde-agent           Or any other polkit agent

Install with:
  $ sudo xbps-install -S cliphist cava wlsunset
or
  $ xi cliphist cava wlsunset power-profiles-daemon ddcutil \
       xdg-desktop-portal python3 evolution-data-server polkit-kde-agent

Compositor integration:
  Niri:     spawn-at-startup "qs"
  Hyprland: exec-once=qs
  Sway:     exec qs

Documentation: https://docs.noctalia.dev
═══════════════════════════════════════════════════════════════
