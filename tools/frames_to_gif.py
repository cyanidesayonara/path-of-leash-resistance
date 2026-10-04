"""Join numbered PNG frames (from tools/intro_render.gd) into an animated GIF.

    python tools/frames_to_gif.py FRAMES_DIR OUT.gif [fps]

One shared palette for the whole clip, so colours do not flicker frame to
frame, and identical consecutive frames merged (the intro animates on twos).
"""
import glob
import os
import sys

from PIL import Image


def main() -> None:
    frames_dir, out = sys.argv[1], sys.argv[2]
    fps = float(sys.argv[3]) if len(sys.argv) > 3 else 15.0
    paths = sorted(glob.glob(os.path.join(frames_dir, "f*.png")))
    frames = [Image.open(p).convert("RGB") for p in paths]
    # one palette from a strip of sample frames across the clip
    sample = Image.new("RGB", (frames[0].width, frames[0].height * 6))
    for i in range(6):
        sample.paste(frames[min(len(frames) - 1, i * len(frames) // 6)], (0, i * frames[0].height))
    pal = sample.quantize(colors=255, method=Image.Quantize.MEDIANCUT)
    q = [f.quantize(palette=pal, dither=Image.Dither.FLOYDSTEINBERG) for f in frames]
    # merge runs of identical frames into longer holds
    out_frames, durations = [], []
    step = int(round(1000.0 / fps))
    for f in q:
        if out_frames and f.tobytes() == out_frames[-1].tobytes():
            durations[-1] += step
        else:
            out_frames.append(f)
            durations.append(step)
    out_frames[0].save(out, save_all=True, append_images=out_frames[1:], duration=durations, loop=0, optimize=False)
    print("gif: %s (%d frames, %.1fs)" % (out, len(out_frames), sum(durations) / 1000.0))


if __name__ == "__main__":
    main()
