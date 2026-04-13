# audio-waveform.yazi — Developer Notes

## What This Plugin Does

Yazi previewer plugin for audio files. Shows metadata (codec, sample rate, duration, etc.) and an ASCII block waveform in the Yazi preview pane.

## Architecture

`main.lua` resolves the path to `bin/waveform` and calls it via Yazi's `Command` API. The binary handles everything: ffprobe metadata, ffmpeg PCM decoding, and waveform rendering.

There is no Python component anymore; everything is implemented in Rust and Lua.

## Rust Binary

Native binary at `bin/waveform` (compiled for the host architecture). The binary:
- Accepts `<width> <height> -- <path>` as CLI arguments
- Calls `ffprobe` for metadata (JSON) including format/stream tags and technical fields
- Calls `ffmpeg` for raw PCM
- Computes waveform columns in Rust
- Streams text frames to stdout delimited by markers:
  - `<<<FRAME>>>` then lines, ending with `<<<END>>>`
- Emits a first frame immediately (with LOUDNESS placeholder for all formats), then a second frame with LOUDNESS filled in when analysis completes.
- `main.lua` spawns the binary and reads line-by-line, buffering between markers and pushing frames into `ui.Text.parse(...)`.

### ffprobe fields
- `format`: `format_name`, `format_long_name`, `duration`, `size`, `bit_rate`, and all `format_tags`
- `streams[*]` (audio stream): `index`, `codec_name`, `codec_long_name`, `codec_type`, `sample_rate`, `channels`, `channel_layout`, `bits_per_sample`, `bit_rate`, `sample_fmt`, `block_align`, `nb_frames`, `time_base`, `start_time`, `duration_ts`, plus all `stream_tags`

We probe tags because WAV files often store INFO/BWF/iXML metadata in separate chunks that ffprobe exposes as tags.

### Metadata layout in TUI
The metadata box uses fixed positions with grey N/A for core technical fields to avoid layout shifts. All sections are always displayed; when a section does not apply to the current file type, it shows “Unavailable for <TYPE>”. In such cases, or when a section has no data, the section title is rendered in grey instead of its usual color.
- Header row: bold filename in the top border
- SUMMARY section: three rows — `Duration`, `Size`, `Overall BR`
- FORMAT section (two fixed rows)
  - `Container | Codec`
  - `Encoding | Endianness`
- AUDIO section (two fixed rows)
  - `Channels | Sample Rate`
  - `Bit Depth | Bitrate`
- TAGS section (INFO/common tags; always shown)
  - `Title | Artist`
  - `Album | Track`
  - `Year | Genre`
  - `Comment | Encoder` (Comment wraps with a hanging indent under its label)
- IXML section (always shown)
  - For WAV/RF64/BW64 (BWF-like), displays fields or “No iXML data” when missing
  - For other formats, displays “Unavailable for <TYPE>”
  - `Project | Scene`
  - `Take | Tape`
  - `Note | Location`
  - `Timecode | TC Rate`
  - `iXML Version | Speed SR`

- BEXT section (always shown)
  - For WAV/RF64/BW64, displays fields or “No BEXT data”
  - For other formats, displays “Unavailable for <TYPE>”
  - `Description | Originator`
  - `Originator Ref | Origination`
  - `Time Reference | UMID`
  - `Loudness (LV) | LRA`
  - `Max True Peak | Max Short-term`
  - `Coding History` (wraps with hanging indent)

- TECHNICAL section (always shown)
  - For WAV/RF64/BW64, displays fields when available or “No technical data”
  - For other formats, displays “Unavailable for <TYPE>”
  - `Block Align | Byte Rate`
  - `Time Base | Start Time`
  - `Frames | Duration TS`
  - `Sample Format | Layout`
\n+- LOUDNESS section (all formats)
  - First frame shows `Integrated LUFS` as “Calculating…”.
  - After ffmpeg ebur128 analysis finishes, updates `Integrated LUFS` and optionally adds `LRA`.

Colors: each box section title uses a distinct color; values are white; N/A is grey. When a section is unavailable for the file type or has no data, its title is grey instead of its usual color.
- SUMMARY: cyan
- FORMAT: yellow
- AUDIO: blue
- TAGS: magenta
- iXML: red
- BEXT: green
- TECHNICAL: white
- LOUDNESS: orange (256-color 38;5;208)
- WAVEFORM: purple (256-color 38;5;135), greys out if no audio data

### iXML support and parsing
iXML is primarily used in WAV/BWF (and RF64/BW64 variants). For these, the IXML box is always shown; if no iXML is present it reads “No iXML data”. Many compressed formats don’t carry iXML; for those, the IXML box is omitted unless an `ixml` tag exists.

If `format.tags.ixml` (or `stream.tags.ixml`) exists, the binary parses a handful of common fields from the XML string without external crates:
- Project, Scene, Take, Tape, Note, Location, IXML_VERSION, TIMECODE, TIMECODE_RATE (+ TIMECODE_FLAG), SPEED/SAMPLE_RATE

The parser is intentionally lightweight and case-insensitive. It only supports simple `<TAG>value</TAG>` forms and CDATA; it won’t handle complex/namespaced structures. Unknown/missing fields display as N/A.

## Yazi Plugin API — Key Points

All from source at `~/development/yazi`.

### Command
Defined in `yazi-binding/src/process/command.rs`. Wraps `tokio::process::Command`.

```lua
local out, err = Command("ffprobe"):arg(args):output()
-- out.stdout is a string; out.status.success is bool

local child, err = Command(bin):arg(args):stdout(Command.PIPED):spawn()
child:read_line()  -- async streaming
```

Modes: `Command.NULL`, `Command.PIPED`, `Command.INHERIT`

### Preview job fields
- `job.area.w` / `job.area.h` — terminal columns/rows available
- `job.file.path` — full path to file being previewed (Url type, use `tostring()`)
- `job.file.name` — filename
- `job.file.cha.size` — file size in bytes
- `job.skip` — scroll offset

### Rendering
```lua
ya.preview_widget(job, ui.Text(lines):area(job.area):wrap(ui.Wrap.YES))
```

## Resolving the Plugin Directory from Lua

There is no `ya.plugin_dir` in the Lua API. Yazi resolves it as:
1. `$YAZI_CONFIG_HOME` (if set and absolute)
2. `$XDG_CONFIG_HOME/yazi` (if set and absolute)
3. `~/.config/yazi`

Then plugin dir = `{config_dir}/plugins`.

The plugin loader sets `_id = "audio-waveform"` on the module table (the plugin name without `.yazi`).

Lua snippet to build the binary path:

```lua
local function plugin_bin()
  local config = os.getenv("YAZI_CONFIG_HOME")
    or (os.getenv("XDG_CONFIG_HOME") and os.getenv("XDG_CONFIG_HOME") .. "/yazi")
    or (os.getenv("HOME") .. "/.config/yazi")
  return config .. "/plugins/audio-waveform.yazi/bin/waveform"
end
```

## Build Setup

The Rust source lives in `src/` with a `Cargo.toml` at the plugin root. Build and install:

```sh
cd ~/.config/yazi/plugins/audio-waveform.yazi
cargo build --release
cp target/release/waveform bin/waveform
```

The binary is architecture-specific and must be built locally. The `target/` directory should be gitignored; `bin/waveform` should be committed or rebuilt after cloning on a new machine.

## File Layout

```
audio-waveform.yazi/
├── CLAUDE.md
├── README.md
├── main.lua          # Lua plugin entry point — spawns the Rust binary and streams frames
├── bin/
│   └── waveform     # compiled Rust binary
└── src/
    └── main.rs      # Rust source
```
