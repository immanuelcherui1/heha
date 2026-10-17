"""Optional real browser screencast using Chromium CDP and system FFmpeg.

Only rendered pixels are recorded. HTTP bodies, cookies and tokens are not
captured. This uses the installed FFmpeg rather than downloading another copy.
"""
import base64;
import time;
import subprocess;
import from pathlib { Path }

obj DemoRecorder {
    has directory: str;
    has session: any = None, frames: list[tuple[str, float]] = [], started: float = 0.0;

    def start(context: any, page: any) {
        Path(self.directory).mkdir(parents=True, exist_ok=True);
        self.started = time.monotonic();
        self.session = context.new_cdp_session(page);
        self.session.on("Page.screencastFrame", self.capture);
        self.session.send("Page.startScreencast", {"format": "jpeg", "quality": 75, "maxWidth": 1440, "maxHeight": 1050, "everyNthFrame": 2});
    }

    def capture(frame: dict) {
        filename = self.directory + "/frame-" + str(len(self.frames)).zfill(6) + ".jpg";
        Path(filename).write_bytes(base64.b64decode(str(frame["data"])));
        self.frames.append((filename, time.monotonic() - self.started));
        self.session.send("Page.screencastFrameAck", {"sessionId": frame["sessionId"]});
    }

    def finish() -> str {
        self.session.send("Page.stopScreencast");
        if len(self.frames) < 2 { raise ValueError("No useful demo frames were captured."); }
        manifest = Path(self.directory + "/frames.txt");
        lines: list[str] = [];
        for (index, frame) in enumerate(self.frames) {
            filename = str(Path(frame[0]).resolve());
            duration: float = float(str(self.frames[index + 1][1])) - float(str(frame[1])) if index + 1 < len(self.frames) else 2.0;
            lines.append("file '" + filename + "'");
            lines.append("duration " + str(max(0.02, duration)));
        }
        lines.append("file '" + str(Path(self.frames[-1][0]).resolve()) + "'");
        manifest.write_text("\n".join(lines));
        output = str(Path(self.directory + "/heha-demo.mp4").resolve());
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "concat", "-safe", "0", "-i", str(manifest), "-vf", "scale=1440:1050:force_original_aspect_ratio=decrease,pad=1440:1050:(ow-iw)/2:(oh-ih)/2:color=0xfaf9f5", "-r", "20", "-c:v", "libx264", "-preset", "fast", "-crf", "25", "-pix_fmt", "yuv420p", "-movflags", "+faststart", output], check=True);
        return output;
    }
}
