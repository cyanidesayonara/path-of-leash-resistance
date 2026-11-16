"""Join numbered PNG frames (from tools/intro_render.gd) into an animated GIF.

    python tools/frames_to_gif.py FRAMES_DIR OUT.gif [fps] [--colors=N] [--no-dither] [--first=I] [--last=I]

--colors and --no-dither trade a little smoothness for a far smaller file (the
website's clips use both); --first and --last keep only that range of frames.
One shared palette for the whole clip, so colours do not flicker frame to
frame, and identical consecutive frames merged (the intro animates on twos).
"""
import glob
import os
import sys

from PIL import Image


def main() -> None:
    flags = [a for a in sys.argv[1:] if a.startswith("--")]
    pos = [a for a in sys.argv[1:] if not a.startswith("--")]
    frames_dir, out = pos[0], pos[1]
    fps = float(pos[2]) if len(pos) > 2 else 15.0
    colors, dither, first, last = 255, Image.Dither.FLOYDSTEINBERG, 0, None
    for f in flags:
        if f.startswith("--colors="):
            colors = int(f.split("=", 1)[1])
        elif f == "--no-dither":
            dither = Image.Dither.NONE
        elif f.startswith("--first="):
            first = int(f.split("=", 1)[1])
        elif f.startswith("--last="):
            last = int(f.split("=", 1)[1]) + 1
    paths = sorted(glob.glob(os.path.join(frames_dir, "f*.png")))[first:last]
    frames = [Image.open(p).convert("RGB") for p in paths]
    # one palette from a strip of sample frames across the clip
    sample = Image.new("RGB", (frames[0].width, frames[0].height * 6))
    for i in range(6):
        sample.paste(frames[min(len(frames) - 1, i * len(frames) // 6)], (0, i * frames[0].height))
    pal = sample.quantize(colors=colors, method=Image.Quantize.MEDIANCUT)
    q = [f.quantize(palette=pal, dither=dither) for f in frames]
    # merge runs of identical frames into longer holds
    out_frames, durations = [], []
    step = int(round(1000.0 / fps))
    for f in q:
        if out_frames and f.tobytes() == out_frames[-1].tobytes():
            durations[-1] += step
        else:
            out_frames.append(f)
            durations.append(step)
    out_frames[0].save(out, save_all=True, append_images=out_frames[1:], duration=durations, loop=0, optimize=dither == Image.Dither.NONE)
    print("gif: %s (%d frames, %.1fs)" % (out, len(out_frames), sum(durations) / 1000.0))


if __name__ == "__main__":
    main()
