use std::{
    env,
    io::{Read, Write},
    path::Path,
    process::{Child, Command, Stdio},
};

use serde_json::Value;

const MAX_SECONDS: f64 = 25.0;
const SAMPLE_RATE: u32 = 4_000;

// ─── ANSI ────────────────────────────────────────────────────────────────────

const R: &str = "\x1b[0m"; // reset
const DIM: &str = "\x1b[2m"; // dim        → borders, labels
const B: &str = "\x1b[1m"; // bold        → filename
const GRN: &str = "\x1b[92m"; // green       → values: duration; title: BEXT
const CYN: &str = "\x1b[96m"; // cyan        → values: size/bitrate/sample rate; title: SUMMARY
const YLW: &str = "\x1b[93m"; // yellow      → title: FORMAT
const BLU: &str = "\x1b[94m"; // blue        → title: AUDIO
const MAG: &str = "\x1b[95m"; // magenta     → title: TAGS
const RED: &str = "\x1b[91m"; // red         → title: iXML
const GRY: &str = "\x1b[90m"; // grey        → N/A placeholders; title: WAVEFORM
const WHT: &str = "\x1b[97m"; // white       → entry values; title: TECHNICAL
const ORA: &str = "\x1b[38;5;208m"; // orange  → title: LOUDNESS
const PPL: &str = "\x1b[38;5;135m"; // purple  → title: WAVEFORM
const BLK: &str = "\x1b[5m";  // blink       → status placeholders

// ─── String helpers ───────────────────────────────────────────────────────────

/// Visible column count — strips ANSI escapes, counts UTF-8 leading bytes.
fn vlen(s: &str) -> usize {
    let b = s.as_bytes();
    let mut n = 0usize;
    let mut i = 0;
    while i < b.len() {
        if b[i] == 0x1b && b.get(i + 1) == Some(&b'[') {
            i += 2;
            while i < b.len() && b[i] != b'm' {
                i += 1;
            }
            i += 1;
        } else {
            if b[i] & 0xc0 != 0x80 {
                n += 1;
            }
            i += 1;
        }
    }
    n
}

/// Pad `s` to `width` visible columns with trailing spaces.
fn rpad(s: &str, width: usize) -> String {
    let n = vlen(s);
    format!("{s}{}", " ".repeat(width.saturating_sub(n)))
}

/// Truncate a plain (no-ANSI) string to at most `max` visible chars.
fn trunc(s: &str, max: usize) -> String {
    let chars: Vec<char> = s.chars().collect();
    if chars.len() <= max {
        return s.to_owned();
    }
    chars[..max.saturating_sub(1)].iter().collect::<String>() + "…"
}

// ─── Box / border helpers ────────────────────────────────────────────────────
//
// Outer box uses single-line rounded corners:  ╭─  ─╮  │  │  ╰─  ─╯
// Section dividers use mixed single/double:    ╞══  ══╡
//   (╞ and ╡ connect to the vertical │ above/below while having ══ horizontally)
//
// Every function produces a string of exactly `width` visible columns.

fn dashes(n: usize) -> String {
    "─".repeat(n)
}
fn equals(n: usize) -> String {
    "═".repeat(n)
}

/// "╭─ TITLE ─────╮"  title_ansi may contain ANSI codes; vlen() handles them.
fn top_border(title: &str, width: usize) -> String {
    // visible: ╭(1) ─(1) space(1) title space(1) fill ╮(1) = 5 + vlen(title) + fill
    let f = dashes(width.saturating_sub(5 + vlen(title)));
    format!("{DIM}╭─ {R}{title} {DIM}{f}╮{R}")
}

/// "╞══ TITLE ════╡"  — section separator inside the box.
fn section_border(title: &str, width: usize) -> String {
    // visible: ╞(1) ═(1) ═(1) space(1) title space(1) fill ╡(1) = 6 + vlen(title) + fill
    let f = equals(width.saturating_sub(6 + vlen(title)));
    format!("{DIM}╞══ {R}{title} {DIM}{f}╡{R}")
}

/// "╰─────────────╯"
fn bottom_border(width: usize) -> String {
    format!("{DIM}╰{}╯{R}", dashes(width.saturating_sub(2)))
}

/// "│ CONTENT              │"  —  inner width = width − 4  (one space each side)
fn meta_row(content: &str, width: usize) -> String {
    let inner = width.saturating_sub(4);
    format!("{DIM}│{R} {} {DIM}│{R}", rpad(content, inner))
}

/// "│CONTENT│"  — no padding spaces; used for waveform rows.
fn wave_row(content: &str) -> String {
    format!("{DIM}│{R}{content}{DIM}│{R}")
}

// ─── Label / value formatting ─────────────────────────────────────────────────

// Label column width (visible), including 2-space left indent.
// "Sample Rate" is 11 chars → LW = 13.
const LW: usize = 13;

/// Dim label left-aligned in LW columns, then normal value.
fn kv(label: &str, value: &str) -> String {
    format!("{DIM}{}{R}  {value}", rpad(&format!("  {label}"), LW))
}

/// Dim label left-aligned in LW columns, then colored value.
fn kvc(label: &str, value: &str, color: &str) -> String {
    format!(
        "{DIM}{}{R}  {color}{value}{R}",
        rpad(&format!("  {label}"), LW)
    )
}

/// Dim label left-aligned; value is Some(colored) or None → grey N/A.
fn kvc_opt(label: &str, value: Option<&str>, color: &str) -> String {
    match value {
        Some(v) if !v.is_empty() => kvc(label, v, color),
        _ => format!("{DIM}{}{R}  {GRY}N/A{R}", rpad(&format!("  {label}"), LW)),
    }
}

/// One meta_row from a label+value pair.
fn detail(label: &str, value: &str, width: usize) -> String {
    meta_row(&kv(label, value), width)
}

/// Two label+value pairs side-by-side in one meta_row.
/// Each pair occupies `col` visible columns; the row's inner width = width − 4.
fn detail2(l1: &str, v1: &str, l2: &str, v2: &str, width: usize) -> String {
    // Provide a visible center divider: " │ " (3 columns) in dim color.
    let vsep = format!(" {DIM}│{R} ");
    let inner = width.saturating_sub(4);
    let col = inner.saturating_sub(3) / 2; // subtract divider width
    let left = rpad(&kv(l1, v1), col);
    let right = kv(l2, v2);
    meta_row(&format!("{left}{vsep}{right}"), width)
}

/// Colored variant of `detail`
fn detail_c(label: &str, value: &str, color: &str, width: usize) -> String {
    meta_row(&kvc(label, value, color), width)
}

/// Colored variant of `detail2`, with a dim center divider.
fn detail2_c(l1: &str, v1: &str, c1: &str, l2: &str, v2: &str, c2: &str, width: usize) -> String {
    let vsep = format!(" {DIM}│{R} ");
    let inner = width.saturating_sub(4);
    let col = inner.saturating_sub(3) / 2;
    let left = rpad(&kvc(l1, v1, c1), col);
    let right = kvc(l2, v2, c2);
    meta_row(&format!("{left}{vsep}{right}"), width)
}

/// `detail2` that accepts optional values and prints grey N/A when missing.
fn detail2_c_opt(
    l1: &str,
    v1: Option<&str>,
    c1: &str,
    l2: &str,
    v2: Option<&str>,
    c2: &str,
    width: usize,
) -> String {
    let vsep = format!(" {DIM}│{R} ");
    let inner = width.saturating_sub(4);
    let col = inner.saturating_sub(3) / 2;
    let left = rpad(&kvc_opt(l1, v1, c1), col);
    let right = kvc_opt(l2, v2, c2);
    meta_row(&format!("{left}{vsep}{right}"), width)
}

/// Wrap plain text into lines up to `width` visible columns.
fn wrap_text(s: &str, width: usize) -> Vec<String> {
    if width == 0 {
        return vec![String::new()];
    }
    let mut lines: Vec<String> = Vec::new();
    let mut cur = String::new();
    let mut cur_w = 0usize;
    for word in s.split_whitespace() {
        let wl = word.chars().count();
        if cur_w == 0 {
            // start of line: put the word even if it exceeds width (rare long token)
            cur.push_str(word);
            cur_w = wl;
            if cur_w > width {
                lines.push(std::mem::take(&mut cur));
                cur_w = 0;
            }
        } else if cur_w + 1 + wl <= width {
            cur.push(' ');
            cur.push_str(word);
            cur_w += 1 + wl;
        } else {
            lines.push(std::mem::take(&mut cur));
            cur.push_str(word);
            cur_w = wl;
            if cur_w > width {
                lines.push(std::mem::take(&mut cur));
                cur_w = 0;
            }
        }
    }
    if !cur.is_empty() {
        lines.push(cur);
    }
    if lines.is_empty() {
        lines.push(String::new());
    }
    lines
}

/// Single-column row where the value can wrap with a hanging indent under its label.
fn detail_leftwrap(label: &str, value: &str, color: &str, width: usize) -> Vec<String> {
    let inner = width.saturating_sub(4);
    let prefix_first = format!("{DIM}{}{R}  ", rpad(&format!("  {label}"), LW));
    let prefix_cont  = format!("{DIM}{}{R}  ", rpad("  ", LW));
    let avail = inner.saturating_sub(LW + 2);
    let mut rows = Vec::new();
    let parts = wrap_text(value, avail);
    for (i, seg) in parts.into_iter().enumerate() {
        let prefix = if i == 0 { &prefix_first } else { &prefix_cont };
        let line = format!("{prefix}{color}{seg}{R}");
        rows.push(meta_row(&line, width));
    }
    if rows.is_empty() { rows.push(meta_row(&format!("{DIM}{}{R}", rpad(&format!("  {label}"), LW)), width)); }
    rows
}

/// Two-column row where the LEFT value can wrap with a hanging indent under its label.
/// Right column only renders on the first line; continuation rows leave it blank.
fn detail2_leftwrap(
    l_label: &str,
    l_value: &str,
    l_color: &str,
    r_label: &str,
    r_value: Option<&str>,
    r_color: &str,
    width: usize,
) -> Vec<String> {
    let vsep = format!(" {DIM}│{R} ");
    let inner = width.saturating_sub(4);
    let col = inner.saturating_sub(3) / 2;
    let prefix_first = format!("{DIM}{}{R}  ", rpad(&format!("  {l_label}"), LW));
    let prefix_cont = format!("{DIM}{}{R}  ", rpad("  ", LW));
    let avail = col.saturating_sub(LW + 2);
    let mut left_lines = wrap_text(l_value, avail);
    if left_lines.is_empty() {
        left_lines.push(String::new());
    }

    let right_first = kvc_opt(r_label, r_value, r_color);
    let mut rows = Vec::new();
    for (i, seg) in left_lines.into_iter().enumerate() {
        let prefix = if i == 0 { &prefix_first } else { &prefix_cont };
        let left = format!("{prefix}{l_color}{seg}{R}");
        let left_padded = rpad(&left, col);
        let right = if i == 0 {
            right_first.clone()
        } else {
            String::new()
        };
        let right_padded = rpad(&right, col);
        rows.push(meta_row(
            &format!("{left_padded}{vsep}{right_padded}"),
            width,
        ));
    }
    rows
}

// ─── Audio helpers ────────────────────────────────────────────────────────────

fn human_size(b: u64) -> String {
    const U: &[&str] = &["B", "KB", "MB", "GB", "TB"];
    let mut n = b as f64;
    let mut i = 0;
    while n >= 1024.0 && i < U.len() - 1 {
        n /= 1024.0;
        i += 1;
    }
    if i == 0 {
        format!("{b} B")
    } else {
        format!("{n:.1} {}", U[i])
    }
}

fn fmt_duration(s: f64) -> String {
    let t = s as u64;
    let h = t / 3600;
    let m = (t % 3600) / 60;
    let s = t % 60;
    if h > 0 {
        format!("{h}:{m:02}:{s:02}")
    } else {
        format!("{m}:{s:02}")
    }
}

fn derive_encoding(codec: &str, fmt: &str) -> (Option<&'static str>, Option<&'static str>) {
    if codec.starts_with("pcm_") {
        let end = if codec.ends_with("le") || fmt.ends_with("le") {
            Some("little-endian")
        } else if codec.ends_with("be") || fmt.ends_with("be") {
            Some("big-endian")
        } else {
            None
        };
        (Some("PCM"), end)
    } else {
        let enc = match codec {
            "mp3" => "MP3",
            "aac" => "AAC",
            "flac" => "FLAC",
            "alac" => "ALAC",
            "opus" => "Opus",
            "vorbis" => "Vorbis",
            "ac3" => "AC-3",
            "eac3" => "E-AC-3",
            "dts" => "DTS",
            _ => return (None, None),
        };
        (Some(enc), None)
    }
}

// ─── Subprocess helpers ───────────────────────────────────────────────────────

fn spawn_ffprobe(path: &str) -> Option<Child> {
    Command::new("ffprobe")
        .args([
            "-v",
            "error",
            "-show_entries",
            "format=format_name,format_long_name,duration,size,bit_rate:\
                stream=index,codec_name,codec_long_name,codec_type,sample_rate,\
                channels,channel_layout,bits_per_sample,bit_rate,sample_fmt,\
                block_align,nb_frames,time_base,start_time,duration_ts:\
                format_tags:stream_tags",
            "-of",
            "json",
            "--",
            path,
        ])
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
        .ok()
}

// ─── Tags / iXML helpers ─────────────────────────────────────────────────────

fn get_ci<'a>(obj: Option<&serde_json::Map<String, Value>>, keys: &[&str]) -> Option<String> {
    let obj = obj?;
    // search case-insensitively across provided keys and existing keys
    for (k, v) in obj.iter() {
        let kl = k.to_ascii_lowercase();
        if keys.iter().any(|t| kl == t.to_ascii_lowercase()) {
            if let Some(s) = v.as_str() {
                return Some(s.to_owned());
            }
        }
    }
    None
}

fn xml_unescape(s: &str) -> String {
    s.replace("&lt;", "<")
        .replace("&gt;", ">")
        .replace("&amp;", "&")
        .replace("&quot;", "\"")
        .replace("&apos;", "'")
}

fn find_xml_tag(xml: &str, tag: &str) -> Option<String> {
    let lower = xml.to_ascii_lowercase();
    let tag_l = tag.to_ascii_lowercase();
    let open_idx = lower.find(&format!("<{}", tag_l))?; // handles <tag> and <tag attr="...">
    let start = lower[open_idx..].find('>')? + open_idx + 1;
    let close_pat = format!("</{}>", tag_l);
    let end = lower[start..].find(&close_pat)? + start;
    let mut val = xml[start..end].to_string();
    // strip CDATA wrapper if present
    /* if val.trim_start().starts_with("<![CDATA[") {
        let s = val.find("<![CDATA[").unwrap() + 9;
        if let Some(e) = val.find(]]>"".trim_matches('"')) { // cannot easily write ]]> in raw
            // Fallback simple removal below if the above fails
        }
        // Simple removal
        if let Some(c) = val.find("]]>" ) { val = val[s..c].to_string(); }
    } */
    // collapse newlines/whitespace to single spaces, trim
    let collapsed = val.split_whitespace().collect::<Vec<_>>().join(" ");
    Some(xml_unescape(&collapsed))
}

#[derive(Default)]
struct Ixml {
    project: Option<String>,
    scene: Option<String>,
    take: Option<String>,
    tape: Option<String>,
    note: Option<String>,
    location: Option<String>,
    ixml_version: Option<String>,
    timecode: Option<String>,
    tc_rate: Option<String>,
    tc_flag: Option<String>,
    speed_sample_rate: Option<String>,
}

fn xml_get(xml: &str, tag: &str) -> Option<String> {
    let lower = xml.to_ascii_lowercase();
    let tag_l = tag.to_ascii_lowercase();
    let open_idx = lower.find(&format!("<{}", tag_l))?; // <tag ...>
    let start = lower[open_idx..].find('>')? + open_idx + 1;
    let close_pat = format!("</{}>", tag_l);
    let end = lower[start..].find(&close_pat)? + start;
    let mut val = xml[start..end].to_string();
    let trimmed = val.trim_start();
    if trimmed.starts_with("<![CDATA[") {
        if let Some(s) = val.find("<![CDATA[") {
            let s1 = s + 9;
            if let Some(e) = val[s1..].find("]]>") {
                val = val[s1..s1 + e].to_string();
            }
        }
    }
    let collapsed = val.split_whitespace().collect::<Vec<_>>().join(" ");
    Some(xml_unescape(&collapsed))
}

fn parse_ixml(xml: &str) -> Ixml {
    let mut x = Ixml::default();
    x.project = xml_get(xml, "PROJECT");
    x.scene = xml_get(xml, "SCENE");
    x.take = xml_get(xml, "TAKE");
    x.tape = xml_get(xml, "TAPE");
    x.note = xml_get(xml, "NOTE");
    x.location = xml_get(xml, "LOCATION");
    x.ixml_version = xml_get(xml, "IXML_VERSION");
    x.timecode = xml_get(xml, "TIMECODE");
    x.tc_rate = xml_get(xml, "TIMECODE_RATE");
    x.tc_flag = xml_get(xml, "TIMECODE_FLAG");
    if let Some(sr) = xml_get(xml, "SAMPLE_RATE") {
        x.speed_sample_rate = Some(sr);
    }
    x
}

fn spawn_ffmpeg(path: &str) -> Option<Child> {
    Command::new("ffmpeg")
        .args([
            "-v",
            "error",
            "-t",
            &MAX_SECONDS.to_string(),
            "-i",
            path,
            "-ac",
            "1",
            "-ar",
            &SAMPLE_RATE.to_string(),
            "-f",
            "s16le",
            "-acodec",
            "pcm_s16le",
            "-",
        ])
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
        .ok()
}

// ─── Waveform renderer ────────────────────────────────────────────────────────

fn render_waveform(raw: &[u8], width: usize, height: usize) -> Vec<String> {
    if raw.len() < 4 {
        return vec!["(no audio data)".into()];
    }

    let (sw, sh) = (width * 2, height * 4);
    let top_sh = sh / 2;
    let bot_sh = sh - top_sh;

    let samples: Vec<i32> = raw
        .chunks_exact(2)
        .map(|c| i16::from_le_bytes([c[0], c[1]]) as i32)
        .collect();

    let per = (samples.len() / sw).max(1);
    let mut pos = vec![0i32; sw];
    let mut neg = vec![0i32; sw];
    for sx in 0..sw {
        let end = ((sx + 1) * per).min(samples.len());
        for &v in &samples[sx * per..end] {
            if v > 0 {
                pos[sx] = pos[sx].max(v);
            } else if v < 0 {
                neg[sx] = neg[sx].max(-v);
            }
        }
    }

    let peak = pos.iter().chain(neg.iter()).copied().max().unwrap_or(1) as f32;
    if peak == 0.0 {
        return vec!["(silent)".into()];
    }

    let filled = |sx: usize, sy: usize| -> bool {
        let (norm, thr) = if sy < top_sh {
            (pos[sx] as f32 / peak, (top_sh - sy) as f32 / top_sh as f32)
        } else {
            (
                neg[sx] as f32 / peak,
                (sy - top_sh + 1) as f32 / bot_sh as f32,
            )
        };
        norm >= thr
    };

    const BITS: [[u8; 4]; 2] = [[0x01, 0x02, 0x04, 0x40], [0x08, 0x10, 0x20, 0x80]];

    (0..height)
        .map(|row| {
            (0..width)
                .map(|col| {
                    let mut b = 0u8;
                    for dx in 0..2usize {
                        for dy in 0..4usize {
                            if filled(col * 2 + dx, row * 4 + dy) {
                                b |= BITS[dx][dy];
                            }
                        }
                    }
                    char::from_u32(0x2800 + b as u32).unwrap_or(' ')
                })
                .collect()
        })
        .collect()
}

// ─── Main ────────────────────────────────────────────────────────────────────

fn main() {
    let args: Vec<String> = env::args().collect();
    let sep = args.iter().position(|a| a == "--").unwrap_or(args.len());
    let width: usize = args.get(1).and_then(|s| s.parse().ok()).unwrap_or(80);
    let height: usize = args.get(2).and_then(|s| s.parse().ok()).unwrap_or(12);
    let path = match args.get(sep + 1) {
        Some(p) => p.as_str(),
        None => {
            eprintln!("Usage: waveform <width> <height> -- <path>");
            std::process::exit(1);
        }
    };

    let mut ffprobe = spawn_ffprobe(path);
    let mut ffmpeg = spawn_ffmpeg(path);

    let mut raw = Vec::new();
    if let Some(ref mut c) = ffmpeg {
        if let Some(mut s) = c.stdout.take() {
            let _ = s.read_to_end(&mut raw);
        }
        let _ = c.wait();
    }

    let j: Value = ffprobe
        .as_mut()
        .and_then(|c| {
            let mut out = Vec::new();
            c.stdout.take()?.read_to_end(&mut out).ok()?;
            let _ = c.wait();
            serde_json::from_slice(&out).ok()
        })
        .unwrap_or(Value::Null);

    // ── Parse ─────────────────────────────────────────────────────────────────

    let fmt = &j["format"];
    let audio = j["streams"]
        .as_array()
        .and_then(|ss| {
            ss.iter()
                .find(|s| s["codec_type"].as_str() == Some("audio"))
        })
        .cloned()
        .unwrap_or(Value::Null);

    let filename = Path::new(path)
        .file_name()
        .map(|n| n.to_string_lossy().into_owned())
        .unwrap_or_else(|| path.to_string());
    let file_size = std::fs::metadata(path).ok().map(|m| m.len());
    let duration = fmt["duration"].as_str().and_then(|s| s.parse::<f64>().ok());
    let overall_br = fmt["bit_rate"].as_str().and_then(|s| s.parse::<u64>().ok());
    let container = fmt["format_long_name"]
        .as_str()
        .or_else(|| fmt["format_name"].as_str());
    let codec = audio["codec_long_name"]
        .as_str()
        .or_else(|| audio["codec_name"].as_str());
    let codec_raw = audio["codec_name"].as_str().unwrap_or("");
    let sample_fmt = audio["sample_fmt"].as_str().unwrap_or("");
    let (encoding, endian) = derive_encoding(codec_raw, sample_fmt);
    let channels = audio["channels"].as_u64();
    let ch_layout = audio["channel_layout"].as_str();
    let sample_rate = audio["sample_rate"]
        .as_str()
        .and_then(|s| s.parse::<u32>().ok());
    let bit_depth = audio["bits_per_sample"].as_u64().filter(|&b| b > 0);
    let stream_br = audio["bit_rate"]
        .as_str()
        .and_then(|s| s.parse::<u64>().ok());
    let fmt_tags = fmt["tags"].as_object();
    let str_tags = audio["tags"].as_object();
    let lookup = |keys: &[&str]| get_ci(fmt_tags, keys).or_else(|| get_ci(str_tags, keys));

    // File type label for messages like "Unavailable for MP3".
    let fmt_name_raw = fmt["format_name"].as_str().unwrap_or("");
    let file_type = Path::new(path)
        .extension()
        .and_then(|e| e.to_str())
        .map(|s| s.to_ascii_uppercase())
        .unwrap_or_else(|| fmt_name_raw.split(',').next().unwrap_or(fmt_name_raw).to_ascii_uppercase());

    // ── Assemble ──────────────────────────────────────────────────────────────

    let mut out: Vec<String> = Vec::new();

    // ┌ Header: filename in the top border ────────────────────────────────────
    // "╭─ Filename.m4a ──────────────────────────╮"
    // fixed overhead: ╭─·(3) + ·fill·╮(min 4) = 7, so max name = width - 7
    let max_name = width.saturating_sub(7);
    let name_disp = trunc(&filename, max_name);
    out.push(top_border(&format!("{B}{name_disp}{R}"), width));

    // ┌ SUMMARY section (boxed like others) ───────────────────────────────────
    out.push(section_border(&format!("{CYN}SUMMARY{R}"), width));
    let dur_disp = duration.map(fmt_duration);
    let siz_disp = file_size.map(human_size);
    let brt_disp = overall_br.map(|b| format!("{} kbps", b / 1000));
    out.push(meta_row(
        &kvc_opt("Duration", dur_disp.as_deref(), WHT),
        width,
    ));
    out.push(meta_row(&kvc_opt("Size", siz_disp.as_deref(), WHT), width));
    out.push(meta_row(
        &kvc_opt("Overall BR", brt_disp.as_deref(), WHT),
        width,
    ));

    // ┌ FORMAT section ─────────────────────────────────────────────────────────
    out.push(section_border(&format!("{YLW}FORMAT{R}"), width));
    // Prefer compact two-column rows when adjacent fields are present.
    // Fixed row order; missing values become grey N/A so positions never shift.
    out.push(detail2_c_opt(
        "Container",
        container,
        WHT,
        "Codec",
        codec,
        WHT,
        width,
    ));
    out.push(detail2_c_opt(
        "Encoding",
        encoding,
        WHT,
        "Endianness",
        endian,
        WHT,
        width,
    ));

    // ┌ AUDIO section ──────────────────────────────────────────────────────────
    out.push(section_border(&format!("{BLU}AUDIO{R}"), width));

    // Channels + Sample Rate on the same row when both are present.
    // Always two columns; if a value is missing, show grey N/A.
    let ch_val = channels.map(|ch| match ch_layout {
        Some(l) => format!("{ch} ({l})"),
        None => ch.to_string(),
    });
    let sr_val = sample_rate.map(|sr| format!("{sr} Hz"));
    out.push(detail2_c_opt(
        "Channels",
        ch_val.as_deref(),
        WHT,
        "Sample Rate",
        sr_val.as_deref(),
        WHT,
        width,
    ));

    // Bit Depth + Bitrate on the same row when both are present.
    let bd_val = bit_depth.map(|bd| format!("{bd} bit"));
    let br_val = stream_br.map(|br| format!("{} kbps", br / 1000));
    out.push(detail2_c_opt(
        "Bit Depth",
        bd_val.as_deref(),
        WHT,
        "Bitrate",
        br_val.as_deref(),
        WHT,
        width,
    ));

    // ┌ TAGS section (common INFO metadata) ───────────────────────────────────
    let title = lookup(&["title", "inam"]);
    let artist = lookup(&["artist", "iart", "author"]);
    let album = lookup(&["album", "iprd"]);
    let track = lookup(&["track", "tracknumber", "track_number", "itrk"]);
    let year = lookup(&["date", "year", "icrd"]);
    let genre = lookup(&["genre", "ignr"]);
    let comment = lookup(&["comment", "description", "icmt"]);
    let encoder = lookup(&["encoder", "isft", "software"]);
    let has_tags = [
        title.as_ref(),
        artist.as_ref(),
        album.as_ref(),
        track.as_ref(),
        year.as_ref(),
        genre.as_ref(),
        comment.as_ref(),
        encoder.as_ref(),
    ]
    .iter()
    .any(|o| o.as_ref().map(|s| !s.is_empty()).unwrap_or(false));
    let tags_color = if has_tags { MAG } else { GRY };
    out.push(section_border(&format!("{tags_color}TAGS{R}"), width));
    if has_tags {
        out.push(detail2_c_opt("Title", title.as_deref(), WHT,
                               "Artist", artist.as_deref(), WHT, width));
        out.push(detail2_c_opt("Album", album.as_deref(), WHT,
                               "Track", track.as_deref(), WHT, width));
        out.push(detail2_c_opt("Year", year.as_deref(), WHT,
                               "Genre", genre.as_deref(), WHT, width));
        // Wrap long Comment values with hanging indent; keep Encoder on the first line
        if let Some(ref cmt) = comment {
            for row in detail2_leftwrap("Comment", cmt, WHT, "Encoder", encoder.as_deref(), WHT, width) {
                out.push(row);
            }
        } else {
            out.push(detail2_c_opt("Comment", comment.as_deref(), WHT,
                                   "Encoder", encoder.as_deref(), WHT, width));
        }
    } else {
        out.push(meta_row(&format!("{GRY}No tags present{R}"), width));
    }

    // ┌ IXML section ──────────────────────────────────────────────────────────
    let ixml_raw = lookup(&["ixml"]);
    // Determine if the container is WAV/BWF-like; render IXML box always.
    let fmt_name_l = fmt["format_name"].as_str().unwrap_or("").to_ascii_lowercase();
    let is_wav_like = fmt_name_l.contains("wav") || fmt_name_l.contains("rf64") || fmt_name_l.contains("bw64");
    let ixml_has = is_wav_like && ixml_raw.as_deref().map(|s| !s.is_empty()).unwrap_or(false);
    let ixml_color = if ixml_has { RED } else { GRY };
    out.push(section_border(&format!("{ixml_color}iXML{R}"), width));
    if is_wav_like {
        if let Some(ref ixml_str) = ixml_raw {
            if !ixml_str.is_empty() {
                let ix = parse_ixml(ixml_str);
                let tc_rate_disp = match (ix.tc_rate.as_deref(), ix.tc_flag.as_deref()) {
                    (Some(r), Some(f)) => Some(format!("{r} ({f})")),
                    (Some(r), None) => Some(r.to_string()),
                    (None, Some(f)) => Some(f.to_string()),
                    _ => None,
                };
                let sr_disp = ix.speed_sample_rate.as_deref().map(|s| format!("{s} Hz"));
                out.push(detail2_c_opt("Project", ix.project.as_deref(), WHT,
                                       "Scene",   ix.scene.as_deref(),   WHT, width));
                out.push(detail2_c_opt("Take",    ix.take.as_deref(),     WHT,
                                       "Tape",    ix.tape.as_deref(),     WHT, width));
                out.push(detail2_c_opt("Note",    ix.note.as_deref(),     WHT,
                                       "Location",ix.location.as_deref(), WHT, width));
                out.push(detail2_c_opt("Timecode", ix.timecode.as_deref(), WHT,
                                       "TC Rate", tc_rate_disp.as_deref(), WHT, width));
                out.push(detail2_c_opt("iXML Version", ix.ixml_version.as_deref(), WHT,
                                       "Speed SR",    sr_disp.as_deref(),        WHT, width));
            } else {
                out.push(meta_row(&format!("{GRY}No iXML data{R}"), width));
            }
        } else {
            out.push(meta_row(&format!("{GRY}No iXML data{R}"), width));
        }
    } else {
        out.push(meta_row(&format!("{GRY}Unavailable for {file_type}{R}"), width));
    }

    // ┌ BEXT (BWF) section — WAV-only, conditional ────────────────────────────
    // Prepare BEXT availability and data presence
    let mut bext_has = false;
    if is_wav_like {
        let desc   = lookup(&["description"]);
        let origin = lookup(&["originator"]);
        let origin_ref = lookup(&["originator_reference", "originator_ref"]);
        let odate  = lookup(&["origination_date"]);
        let otime  = lookup(&["origination_time"]);
        let umid   = lookup(&["umid"]);
        let chist  = lookup(&["coding_history"]);
        let tref   = lookup(&["time_reference"]).or_else(|| {
            let low  = lookup(&["time_reference_low"]);
            let high = lookup(&["time_reference_high"]);
            match (low.as_deref(), high.as_deref()) {
                (Some(l), Some(h)) => {
                    let lo = l.parse::<u64>().ok()?; let hi = h.parse::<u64>().ok()?;
                    Some(((hi << 32) + lo).to_string())
                }
                _ => None,
            }
        });
        let lv    = lookup(&["loudness_value"]);
        let lra   = lookup(&["loudness_range"]);
        let mtp   = lookup(&["max_true_peak_level"]);
        let mst   = lookup(&["max_short_term_loudness"]);
        let mm    = lookup(&["max_momentary_loudness"]);

        bext_has = [
            desc.as_ref(), origin.as_ref(), origin_ref.as_ref(), odate.as_ref(),
            otime.as_ref(), tref.as_ref(), umid.as_ref(), chist.as_ref(),
            lv.as_ref(), lra.as_ref(), mtp.as_ref(), mst.as_ref(), mm.as_ref(),
        ].iter().any(|o| o.as_ref().map(|s| !s.is_empty()).unwrap_or(false));

        let bext_color = if bext_has { GRN } else { GRY };
        out.push(section_border(&format!("{bext_color}BEXT{R}"), width));
        if bext_has {
            out.push(detail2_c_opt("Description", desc.as_deref(), WHT,
                                   "Originator", origin.as_deref(), WHT, width));
            let dt = match (odate.as_deref(), otime.as_deref()) {
                (Some(d), Some(t)) => Some(format!("{d} {t}")),
                (Some(d), None)    => Some(d.to_string()),
                (None, Some(t))    => Some(t.to_string()),
                _ => None,
            };
            out.push(detail2_c_opt("Originator Ref", origin_ref.as_deref(), WHT,
                                   "Origination", dt.as_deref(), WHT, width));
            let tref_disp = tref.as_deref().map(|s| format!("{s} samples"));
            out.push(detail2_c_opt("Time Reference", tref_disp.as_deref(), WHT,
                                   "UMID", umid.as_deref(), WHT, width));
            // Loudness rows (if any)
            if lv.is_some() || lra.is_some() {
                let lv_disp  = lv.as_deref().map(|s| format!("{s} LUFS"));
                let lra_disp = lra.as_deref().map(|s| format!("{s} LU"));
                out.push(detail2_c_opt("Loudness (LV)", lv_disp.as_deref(), WHT,
                                       "LRA", lra_disp.as_deref(), WHT, width));
            }
            if mtp.is_some() || mst.is_some() || mm.is_some() {
                let mtp_disp = mtp.as_deref().map(|s| format!("{s} dBTP"));
                let right = if let Some(ref st) = mst { Some(format!("{st} LUFS")) }
                            else if let Some(ref mo) = mm { Some(format!("{mo} LUFS")) }
                            else { None };
                out.push(detail2_c_opt("Max True Peak", mtp_disp.as_deref(), WHT,
                                       "Max Short-term", right.as_deref(), WHT, width));
            }
            // Coding History (wrap)
            if let Some(ref hist) = chist {
                for row in detail_leftwrap("Coding History", hist, WHT, width) { out.push(row); }
            }
        } else {
            out.push(meta_row(&format!("{GRY}No BEXT data{R}"), width));
        }
    } else {
        let bext_color = GRY;
        out.push(section_border(&format!("{bext_color}BEXT{R}"), width));
        out.push(meta_row(&format!("{GRY}Unavailable for {file_type}{R}"), width));
    }

    // ┌ TECHNICAL section — WAV-only, conditional ─────────────────────────────
    // TECHNICAL section — show for all formats; fill where applicable
    let block_align = audio["block_align"].as_u64()
        .or_else(|| audio["block_align"].as_str().and_then(|s| s.parse::<u64>().ok()));
    let channels_u = channels;
    let sr_u = sample_rate;
    let bd_u = bit_depth.map(|b| b as u64);
    let byte_rate = match (sr_u, channels_u, bd_u) {
        (Some(sr), Some(ch), Some(bd)) => Some(((sr as u64) * (ch as u64) * (bd as u64) / 8).to_string()),
        _ => None,
    };
    let time_base = audio["time_base"].as_str().map(|s| s.to_string());
    let start_time = audio["start_time"].as_str().map(|s| s.to_string());
    let nb_frames = audio["nb_frames"].as_str().map(|s| s.to_string()).or_else(|| audio["nb_frames"].as_u64().map(|n| n.to_string()));
    let duration_ts = audio["duration_ts"].as_str().map(|s| s.to_string()).or_else(|| audio["duration_ts"].as_u64().map(|n| n.to_string()));
    let sample_fmt_s = sample_fmt.to_string();
    let layout_disp = ch_layout.map(|s| s.to_string());

    let has_tech = block_align.is_some() || byte_rate.is_some() || time_base.is_some() ||
                   start_time.is_some() || nb_frames.is_some() || duration_ts.is_some() ||
                   !sample_fmt_s.is_empty() || layout_disp.is_some();

    let tech_color = if is_wav_like && has_tech { WHT } else { GRY };
    out.push(section_border(&format!("{tech_color}TECHNICAL{R}"), width));
    if is_wav_like {
        if has_tech {
            let ba_disp = block_align.map(|n| format!("{} bytes", n));
            let br_disp = byte_rate.as_ref().map(|s| format!("{s} B/s"));
            out.push(detail2_c_opt("Block Align", ba_disp.as_deref(), WHT,
                                   "Byte Rate",  br_disp.as_deref(), WHT, width));
            out.push(detail2_c_opt("Time Base", time_base.as_deref(), WHT,
                                   "Start Time", start_time.as_deref(), WHT, width));
            out.push(detail2_c_opt("Frames", nb_frames.as_deref(), WHT,
                                   "Duration TS", duration_ts.as_deref(), WHT, width));
            out.push(detail2_c_opt("Sample Format", if sample_fmt_s.is_empty() { None } else { Some(sample_fmt_s.as_str()) }, WHT,
                                   "Layout", layout_disp.as_deref(), WHT, width));
        } else {
            out.push(meta_row(&format!("{GRY}No technical data{R}"), width));
        }
    } else {
        out.push(meta_row(&format!("{GRY}Unavailable for {file_type}{R}"), width));
    }

    // ┌ LOUDNESS section: Calculating… placeholder initially (all formats) ────
    out.push(section_border(&format!("{ORA}LOUDNESS{R}"), width));
    let calc = format!("{GRY}{BLK}Calculating...{R}");
    out.push(meta_row(&kv("Integrated LUFS", &calc), width));

    // ┌ Waveform section ───────────────────────────────────────────────────────
    // Wave rows use "│content│" with no padding spaces → inner = width − 2.
    let wave_inner = width.saturating_sub(2);
    let wave_color = if raw.len() >= 4 { PPL } else { GRY };
    out.push(section_border(&format!("{wave_color}WAVEFORM{R}"), width));
    for row in render_waveform(&raw, wave_inner, height) {
        out.push(wave_row(&row));
    }

    out.push(bottom_border(width));

    // Stream the first frame immediately, then compute loudness and stream final.
    fn print_frame(lines: &[String]) {
        println!("<<<FRAME>>>");
        for l in lines { println!("{l}"); }
        println!("<<<END>>>");
        let _ = std::io::stdout().flush();
    }
    print_frame(&out);

    // Compute Integrated LUFS via ffmpeg ebur128 filter (full-file analysis)
    let mut loud_i: Option<String> = None;
    let mut loud_lra: Option<String> = None;
    if let Ok(mut c) = Command::new("ffmpeg").args([
        "-hide_banner","-nostats","-vn","-sn","-dn","-i", path,
        "-filter:a","ebur128=peak=true:framelog=quiet","-f","null","-"
    ]).stdout(Stdio::null()).stderr(Stdio::piped()).spawn() {
        if let Some(mut s) = c.stderr.take() {
            let mut buf = String::new(); let _ = s.read_to_string(&mut buf);
            for t in buf.lines().map(|l| l.trim()) {
                if let Some(p) = t.find("I:") {
                    if let Some(num) = t[p+2..].split_whitespace().find(|x| x.chars().any(|c| c.is_ascii_digit() || c=='-' )) {
                        if let Ok(val) = num.parse::<f32>() { loud_i = Some(format!("{val:.1} LUFS")); }
                    }
                } else if let Some(p) = t.find("LRA:") {
                    if let Some(num) = t[p+4..].split_whitespace().find(|x| x.chars().any(|c| c.is_ascii_digit() || c=='-' )) {
                        if let Ok(val) = num.parse::<f32>() { loud_lra = Some(format!("{val:.1} LU")); }
                    }
                }
            }
        }
        let _ = c.wait();
    }

    let mut out2 = out.clone();
    if let Some(idx) = out2.iter().position(|s| s.contains("LOUDNESS")) {
        let loud_color = if loud_i.is_some() || loud_lra.is_some() { ORA } else { GRY };
        out2[idx] = section_border(&format!("{loud_color}LOUDNESS{R}"), width);
        if let Some(ref i) = loud_i {
            out2[idx + 1] = meta_row(&kvc("Integrated LUFS", i, WHT), width);
        } else {
            out2[idx + 1] = meta_row(&kvc("Integrated LUFS", &format!("{GRY}N/A{R}"), WHT), width);
        }
        if let Some(ref lra) = loud_lra {
            out2.insert(idx + 2, meta_row(&kvc("LRA", lra, WHT), width));
        }
    }
    print_frame(&out2);
}
