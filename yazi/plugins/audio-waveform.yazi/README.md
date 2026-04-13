Audio Waveform + Metadata previewer for Yazi

Overview
- Renders an ASCII waveform for audio files in the preview pane.
- Shows rich, well-organized metadata (container, codec/encoding, channels/layout, sample rate, bit depth, endian, bitrate, duration, file info).
- Uses ffmpeg/ffprobe for decoding and analysis.

Requirements
- ffmpeg (ffprobe/ffmpeg) in PATH.
- Python 3.

Notes
- Waveform rendering is limited to the first ~120s for responsiveness.
- Metadata is shown even if waveform cannot be generated.
- Works for common formats: mp3, m4a/aac, flac, wav/pcm, ogg/opus/vorbis, etc.

