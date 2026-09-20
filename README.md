# Matrix Code Rain

A Matrix-inspired [SDDM](https://github.com/sddm/sddm) greeter theme: dense
Katakana code rain animated in QML behind a black-and-green login panel. No
video, no pre-rendered background image — the rain is drawn live and scales to
whatever resolution the greeter is given.

Built for Qt 6 (`sddm-greeter-qt6`) and plain QtQuick. It imports nothing
beyond `QtQuick` itself, so it has no dependency on QtQuick.Controls,
QtQuick.Effects, Qt5Compat or `SddmComponents`.

## Screenshot

![Matrix Code Rain at 3440x1440](screenshot.png)

*3440×1440. The theme is laid out proportionally, not pinned to one
resolution: 1920×1080, 2560×1440, 3440×1440 and 3840×2160 all get the same
composition.*

## Features

- **Animated Matrix-style rain** — drawn in QML, one scene-graph animation per
  stream, no per-frame object churn.
- **Tiny Katakana and code glyphs** — half-width Katakana mixed with digits,
  Latin capitals and symbols, at terminal size rather than movie-poster size.
  Streams vary in speed, length, column position and glyph sequence, the
  leading glyph is brighter, and each stream fades progressively towards its
  tail.
- **Username selection** — a text field pre-filled with the last account to log
  in, replaced by a dropdown when the machine has several visible accounts. Any
  valid local account can still be typed in.
- **Password entry** — masked input, monospace green on near-black, a thin
  border that brightens on focus, Enter to submit.
- **Session selection** — every session SDDM offers, Wayland and X11 alike,
  chosen by mouse or keyboard.
- **Profile image** — a circular avatar with a thin green ring, shipped as a
  theme asset.
- **Shutdown, reboot and suspend** — compact text actions that follow SDDM's
  own capability flags.
- **Responsive ultrawide layout** — one scale factor derived from the screen
  height drives every metric; the rain adds columns rather than stretching.

## Installation

### NixOS

Package the theme directory and point SDDM at it. Nothing needs to be copied
into `/usr/share`:

```nix
{ pkgs, ... }:
let
  matrixCodeRain = pkgs.runCommand "sddm-matrix-code-rain" { } ''
    install -d $out/share/sddm/themes/matrix-code-rain
    cp -r ${pkgs.fetchFromGitHub {
      owner = "r3dg0d";
      repo = "matrix-code-rain-sddm";
      rev = "main";            # pin a commit and hash for reproducibility
      hash = lib.fakeHash;
    }}/. $out/share/sddm/themes/matrix-code-rain/
  '';
in
{
  services.displayManager.sddm = {
    enable = true;
    theme = "matrix-code-rain";
    # The greeter needs a display server of its own: either
    # services.xserver.enable, or SDDM's Wayland greeter as here.
    wayland.enable = true;
    extraPackages = [ pkgs.qt6.qtwayland ];
  };

  environment.systemPackages = [ matrixCodeRain ];

  # Optional: the monospace family the theme prefers.
  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
}
```

`services.displayManager.sddm` reads themes from
`/run/current-system/sw/share/sddm/themes`, which is why adding the package to
`environment.systemPackages` is all the installation this needs.

### Other Linux distributions

```sh
sudo git clone https://github.com/r3dg0d/matrix-code-rain-sddm \
  /usr/share/sddm/themes/matrix-code-rain
```

Then select it in `/etc/sddm.conf` (or a drop-in in `/etc/sddm.conf.d/`):

```ini
[Theme]
Current=matrix-code-rain
```

Replace `assets/pfp.png` with your own square image, and restart the display
manager (or reboot) to see it.

## Configuration

Everything tunable lives in `theme.conf`. Distribution packages should edit
that file; on an immutable system, copy the theme, change the copy, and point
`Current=` at it.

| Key | Default | Meaning |
| --- | --- | --- |
| `background` | `#000000` | Page background. |
| `accentColor` | `#00FF41` | Primary green: text, focused borders, the button. |
| `midColor` | `#00C832` | Secondary green: header, avatar ring, list rows. |
| `dimColor` | `#008F11` | Labels, idle borders. |
| `rainHeadColor` | `#CFFFD8` | The leading glyph of each stream. |
| `neutralColor` | `#BFC6BF` | Status line, so it does not read as "green means fine". |
| `fontFamily` | `JetBrainsMono Nerd Font Mono` | Preferred monospace family. |
| `avatar` | `assets/pfp.png` | Profile image, relative to the theme directory. |
| `avatarSize` | `120` | Avatar diameter in logical pixels, before scaling. |
| `showAvatar` | `true` | Show the avatar at all. |
| `headerText` | *(empty)* | Header line; empty means `<HOSTNAME> // AUTHENTICATION`. |
| `showHeader` | `true` | Show the header line. |
| `showPowerActions` | `true` | Show the power actions. |
| `showSuspend` | `true` | Include suspend among them. |
| `powerVisibility` | `auto` | `auto` follows SDDM's capability flags; `always` shows them regardless (useful with `--test-mode`). |
| `rainFontSize` | `13` | Glyph size in logical pixels, before scaling. |
| `rainColumnSpacing` | `1.65` | Column spacing, as a multiple of the glyph size. |
| `rainMaxColumns` | `260` | Upper bound on the number of streams. |
| `rainMinSpeed` / `rainMaxSpeed` | `45` / `165` | Fall speed range, pixels per second. |
| `rainOpacity` | `0.95` | Opacity of the whole rain layer. |

The font is a preference, not a requirement: the theme picks the first
available family from the configured name, JetBrains Mono, Fira Code, Hack, IBM
Plex Mono and a few common fallbacks, and ends at fontconfig's generic
`monospace`.

## Requirements

- SDDM 0.20 or newer with the Qt 6 greeter (`sddm-greeter-qt6`).
- `qtdeclarative` (QtQuick). Nothing else.
- A monospace font. Any will do; a clean coding face looks best.

## Development

The layout splits into `Main.qml`, `MatrixRain.qml`, `LoginPanel.qml`,
`PowerControls.qml` and the controls under `components/`.

```sh
# static analysis
qmllint -I "$(dirname "$(dirname "$(command -v qmlscene)")")/lib/qt-6/qml" -I . \
  Main.qml MatrixRain.qml LoginPanel.qml PowerControls.qml components/*.qml

# component tests: focus chain, keyboard and mouse handling, model reads
QT_QPA_PLATFORM=offscreen qmltestrunner -input tests

# live preview, without touching the real login screen
sddm-greeter-qt6 --test-mode --theme .
```

`--test-mode` runs without the SDDM daemon, so it reports no power
capabilities; set `powerVisibility=always` while previewing if you want to see
those controls.

`qmllint` reports `unqualified access` for `sddm`, `config`, `userModel` and
`sessionModel`. Those are context properties the greeter injects at runtime and
no theme can declare; `.qmllint.ini` silences that one category and leaves the
rest enabled.

## Credits

- The falling-code motif comes from *The Matrix* (1999); the implementation
  here is original QML.
- Built against SDDM's Qt 6 greeter API: `sddm.login()`, `sddm.powerOff()`,
  `sddm.reboot()`, `sddm.suspend()`, `userModel` and `sessionModel`.
- `assets/pfp.png` is the author's own profile image and is part of this theme.

## License

MIT — see [LICENSE](LICENSE).
