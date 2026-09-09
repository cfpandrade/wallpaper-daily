# wallpaper-daily

Multi-monitor wallpaper rotator for GNOME that pulls fresh images from
[Wallhaven](https://wallhaven.cc) twice a day.

Instead of setting one image per screen, it composes a single canvas that
matches the real pixel geometry of your monitors and applies it with
`picture-options=spanned`, the same mechanism HydraPaper uses. Monitors can be
grouped, so a group of several screens shows one continuous scene rather than
unrelated images side by side.

## Features

- **Native resolution only.** Searches are issued at the exact resolution of
  each monitor group. If the pool is thin it warns instead of serving an
  upscaled image.
- **Rotation aware.** A block taller than it is wide asks Wallhaven for
  portrait ratios instead of cropping a landscape image down to a sliver.
- **Per-machine config.** A `hosts` section keyed by hostname keeps one config
  usable on a laptop and a desk with different connectors.
- **Monitor groups.** Any set of connectors can share one stretched image;
  connectors not listed form their own single-screen group.
- **Combinable themes.** Every key under `themes` becomes a command line flag,
  so `--dark --space` searches for both at once.
- **Theme pools.** Each run picks a random entry from the pool, per group, so
  tastes rotate instead of freezing on one look.
- **Pinning.** `--set` applies a specific Wallhaven image and `--pin` keeps the
  timer from replacing it.
- **Offline reshuffle.** `--shuffle` rearranges what is already downloaded
  without hitting the network.

## Requirements

- GNOME on Wayland or X11, with `gsettings` available
- Python 3
- [Pillow](https://pypi.org/project/Pillow/) to compose the canvas
- PyGObject with GTK 4 to read the monitor layout

On Debian and Ubuntu:

```bash
sudo apt install python3-pil python3-gi gir1.2-gtk-4.0
```

## Install

```bash
git clone https://github.com/cfpandrade/wallpaper-daily.git
cd wallpaper-daily
./install.sh
```

The installer copies the script to `~/.local/bin`, installs the systemd user
units, seeds `~/.config/wallpaper-daily.json` if absent, and enables the timer.

## Usage

```bash
wallpaper-daily                  # rotate every group now
wallpaper-daily --dry-run        # show what would be applied
wallpaper-daily --list-groups    # show detected monitors and groups
wallpaper-daily --save-groups    # bind this machine's monitors to one image
wallpaper-daily --list-themes    # show configured themes
wallpaper-daily --dark --space   # combine two themes for this run
wallpaper-daily --only tv        # rotate a single screen or group
wallpaper-daily --shuffle        # reshuffle local images, no downloads
wallpaper-daily --set 7jl2lv --pin
wallpaper-daily --unpin
wallpaper-daily --toplist --top-range 1M
wallpaper-daily --dark --save-default   # make the timer use this from now on
```

## Configuration

Config lives at `~/.config/wallpaper-daily.json`. See
[`wallpaper-daily.example.json`](wallpaper-daily.example.json) for a starting
point.

| Key | Meaning |
| --- | --- |
| `download_dir` | Where images are cached, one bucket per group |
| `keep_per_bucket` | Images retained per bucket before the oldest are pruned |
| `purity` | Wallhaven purity bits, `100` is SFW only |
| `categories` | Wallhaven category bits: general / anime / people |
| `api_key` | Optional, only needed for NSFW results |
| `min_pool` | Warn when a search returns fewer results than this |
| `sorting` | `random`, `hot`, `toplist`, `views`, `favorites`, `date_added` |
| `top_range` | Toplist window: `1d` `3d` `1w` `1M` `3M` `6M` `1y` |
| `page_spread` | For fixed orderings, pick a random page within this many |
| `default_theme` | Theme the timer uses when no pool is set |
| `theme_pool` | Entries the run picks from at random, global or per group |
| `themes` | Named filters, each exposed as a `--flag` |
| `groups` | Monitor groups, by connector name |
| `hosts` | Per-machine overrides, keyed by hostname |

### Several machines

Connector names do not travel. The `DP-3` on one desk is a different panel on
another, so a config copied between machines silently stops matching and every
monitor ends up with its own wallpaper.

Put the machine-specific part under `hosts`, keyed by hostname. Those keys
override the top level, so one config file works everywhere:

```json
{
  "default_theme": "dark",
  "hosts": {
    "workstation": {
      "groups": [
        { "name": "desk", "connectors": ["DP-1", "DP-2", "DP-3"] }
      ]
    }
  }
}
```

To generate that block for the machine you are sitting at:

```bash
wallpaper-daily --save-groups         # all monitors share one image
wallpaper-daily --save-groups split   # one image per monitor
```

### Finding connectors

Find connector names with `wallpaper-daily --list-groups`.

The layout is read through GDK. Under a systemd timer there may be no display
access, so the last known layout is cached and reused instead of failing.

## API

The only external service is the Wallhaven public API v1.

| Endpoint | Purpose |
| --- | --- |
| `GET https://wallhaven.cc/api/v1/search` | Find candidates for a group |
| `GET https://wallhaven.cc/api/v1/w/{id}` | Resolve one image for `--set` |

Search parameters sent: `ratios`, `atleast`, `purity`, `categories`, `sorting`,
`page`, plus `q` when a theme or group query is set, `colors` for color themes,
`topRange` for toplist ordering, and `apikey` when one is configured. Images
are then fetched from the `path` field of the response.

No key is required for SFW browsing. Anonymous requests are rate limited to 45
per minute; the script sleeps between calls and the timer adds a randomized
delay so runs do not land on the same instant every day.

## Scheduling

The timer fires at 00:00 and 12:00 with `Persistent=true`, so a machine that
was asleep catches up on the next boot, plus a randomized delay of up to 30
minutes.

```bash
systemctl --user list-timers wallpaper-daily.timer
systemctl --user start wallpaper-daily.service   # run once now
journalctl --user -u wallpaper-daily.service -n 50
```

## License

MIT
