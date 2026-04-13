-- Audio Waveform Previewer for Yazi
-- Delegates all work to the compiled Rust binary at bin/waveform.

local M = {}

-- Resolve the absolute path to the waveform binary.
-- Mirrors Yazi's own config-dir resolution (yazi-fs/src/xdg.rs):
--   YAZI_CONFIG_HOME > XDG_CONFIG_HOME/yazi > ~/.config/yazi
local function bin_path()
  local config = os.getenv("YAZI_CONFIG_HOME")
    or (os.getenv("XDG_CONFIG_HOME") and os.getenv("XDG_CONFIG_HOME") .. "/yazi")
    or (os.getenv("HOME") .. "/.config/yazi")
  return config .. "/plugins/audio-waveform.yazi/bin/waveform"
end

function M:peek(job)
  local w = job.area.w or 80
  local h = math.max(6, math.min(16, math.floor((job.area.h or 24) * 0.45)))
  local path = tostring(job.file.path)

  local child, err = Command(bin_path()):arg({ tostring(w), tostring(h), "--", path }):stdout(Command.PIPED):spawn()
  if not child then
    ya.preview_widget(
      job,
      ui.Text.parse("Audio Preview\n─────────────\n(run: cargo build --release && cp target/release/waveform bin/waveform)")
        :area(job.area)
        :wrap(ui.Wrap.YES)
    )
    return
  end

  local buf = {}
  while true do
    local line, e = child:read_line()
    if not line then break end
    line = tostring(line)
    -- Trim trailing CR/LF to make frame markers robust across platforms
    local trimmed = line:gsub("[\r\n]+$", "")
    if trimmed == "<<<FRAME>>>" then
      buf = {}
    elseif trimmed == "<<<END>>>" then
      ya.preview_widget(job, ui.Text.parse(table.concat(buf, "\n")):area(job.area):wrap(ui.Wrap.YES))
    else
      table.insert(buf, trimmed)
    end
  end
end

function M:seek(job) return require("code"):seek(job) end
function M:preload() return true end
function M:fetch() return true end
function M:spot(job) return require("file"):spot(job) end

return M
