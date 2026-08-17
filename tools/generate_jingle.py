#!/usr/bin/env python3
"""Generate the chiptune "Happy Birthday" jingle shipped as media/happy-birthday.ogg.

The melody is public domain (US since 2016, DE/EU since 2017), and this renders it
from scratch instead of using a third-party recording, so the asset is entirely ours.

Requires numpy and oggenc (brew install vorbis-tools). Run from anywhere:

    python3 tools/generate_jingle.py                 # write media/happy-birthday.ogg
    python3 tools/generate_jingle.py --preview DIR   # write 10 volume variants to DIR

Tweak the constants below and re-run to change how the jingle sounds.
"""

import argparse
import math
import os
import shutil
import subprocess
import sys
import tempfile
import wave

import numpy as np

# --- Tweakables ---------------------------------------------------------------

TEMPO_BPM = 200       # Quarter notes per minute. The melody is 25 quarter notes
                      # long, so the jingle lasts 25 * 60 / TEMPO_BPM seconds.
WAVEFORM = "square"   # "square" (8-bit), "triangle" (softer), "saw" (brassy).
DUTY = 0.5            # Square wave duty cycle. 0.25 gives a thinner, nasal tone.
VOLUME = 0.225        # Peak amplitude, 0.0 - 1.0. Chosen by ear in game: 45% of the
                      # original 0.5, i.e. about -6.9 dB quieter.
SAMPLE_RATE = 44100
OGG_QUALITY = 4       # oggenc -q, 0-10.

ATTACK = 0.005        # Envelope, in seconds.
RELEASE = 0.040
GAP = 0.012           # Silence after each note so repeated pitches stay distinct.

VIBRATO_HZ = 5.5      # Slight pitch wobble; set depth to 0 to disable.
VIBRATO_DEPTH = 0.003

# --- Melody -------------------------------------------------------------------

# Happy Birthday in C major, 3/4, with the two-note pickup.
# Durations are in eighth-note units: quarter = 2, dotted eighth = 1.5,
# sixteenth = 0.5, half = 4, dotted half = 6.
NOTES = [
    ("G4", 1.5), ("G4", 0.5),
    ("A4", 2), ("G4", 2), ("C5", 2),
    ("B4", 4), ("G4", 1.5), ("G4", 0.5),
    ("A4", 2), ("G4", 2), ("D5", 2),
    ("C5", 4), ("G4", 1.5), ("G4", 0.5),
    ("G5", 2), ("E5", 2), ("C5", 2),
    ("B4", 2), ("A4", 2), ("F5", 1.5), ("F5", 0.5),
    ("E5", 2), ("C5", 2), ("D5", 2),
    ("C5", 6),
]

# Equal temperament, A4 = 440 Hz.
FREQUENCIES = {
    "G4": 392.00,
    "A4": 440.00,
    "B4": 493.88,
    "C5": 523.25,
    "D5": 587.33,
    "E5": 659.25,
    "F5": 698.46,
    "G5": 783.99,
}

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUTPUT = os.path.join(REPO_ROOT, "media", "happy-birthday.ogg")


def oscillator(phase):
    """Map a 0..1 phase ramp to the configured waveform, in -1..1."""
    if WAVEFORM == "square":
        return np.where(phase % 1.0 < DUTY, 1.0, -1.0)
    if WAVEFORM == "triangle":
        return 4.0 * np.abs((phase % 1.0) - 0.5) - 1.0
    if WAVEFORM == "saw":
        return 2.0 * (phase % 1.0) - 1.0
    raise SystemExit(f"unknown WAVEFORM: {WAVEFORM!r}")


def envelope(length):
    """Linear attack/release so notes neither click nor blur into each other."""
    env = np.ones(length)
    attack = min(int(ATTACK * SAMPLE_RATE), length // 2)
    release = min(int(RELEASE * SAMPLE_RATE), length // 2)
    if attack:
        env[:attack] = np.linspace(0.0, 1.0, attack)
    if release:
        env[-release:] = np.linspace(1.0, 0.0, release)
    return env


def render_note(frequency, seconds):
    length = int(seconds * SAMPLE_RATE)
    t = np.arange(length) / SAMPLE_RATE
    # Integrate the vibrato-modulated frequency to get a continuous phase.
    instantaneous = frequency * (1.0 + VIBRATO_DEPTH * np.sin(2 * np.pi * VIBRATO_HZ * t))
    phase = np.cumsum(instantaneous) / SAMPLE_RATE
    # Rendered at full scale; VOLUME is applied once to the finished melody so that
    # variants are a single multiply rather than a full re-render.
    return oscillator(phase) * envelope(length)


def render_melody():
    eighth = 30.0 / TEMPO_BPM  # A quarter note is 60/BPM seconds.
    chunks = []
    gap = np.zeros(int(GAP * SAMPLE_RATE))
    for name, units in NOTES:
        duration = units * eighth - GAP
        if duration <= 0:
            raise SystemExit("GAP is longer than the shortest note; lower GAP or TEMPO_BPM")
        chunks.append(render_note(FREQUENCIES[name], duration))
        chunks.append(gap)
    return np.concatenate(chunks)


def write_wav(samples, path):
    clipped = np.clip(samples, -1.0, 1.0)
    pcm = (clipped * 32767.0).astype("<i2")
    with wave.open(path, "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(SAMPLE_RATE)
        handle.writeframes(pcm.tobytes())


def encode(samples, path):
    with tempfile.TemporaryDirectory() as tmp:
        wav_path = os.path.join(tmp, "jingle.wav")
        write_wav(samples, wav_path)
        subprocess.run(
            ["oggenc", "-Q", "-q", str(OGG_QUALITY), "-o", path, wav_path],
            check=True,
        )
    return os.path.getsize(path)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--preview",
        metavar="DIR",
        help="write volume variants from 10%% to 100%% of VOLUME into DIR "
             "instead of the shipped file, for picking a level by ear",
    )
    args = parser.parse_args()

    if not shutil.which("oggenc"):
        sys.exit("oggenc not found. Install it with: brew install vorbis-tools")

    melody = render_melody()
    seconds = len(melody) / SAMPLE_RATE

    if args.preview:
        os.makedirs(args.preview, exist_ok=True)
        print(f"{seconds:.2f}s per file, 100% = the current VOLUME of {VOLUME}\n")
        print(f"{'file':28} {'amplitude':>10} {'vs 100%':>9} {'bytes':>8}")
        for percent in range(10, 101, 10):
            path = os.path.join(args.preview, f"happy-birthday-{percent:03d}.ogg")
            size = encode(melody * VOLUME * percent / 100.0, path)
            db = 20.0 * math.log10(percent / 100.0)
            print(f"{os.path.basename(path):28} {VOLUME * percent / 100.0:10.4f} "
                  f"{db:8.1f}dB {size:8d}")
        return

    os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)
    size = encode(melody * VOLUME, OUTPUT)
    print(f"wrote {OUTPUT} ({seconds:.2f}s, {size} bytes, {WAVEFORM} @ {TEMPO_BPM} BPM, "
          f"volume {VOLUME})")


if __name__ == "__main__":
    main()
