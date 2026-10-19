"""Synthesises the silent UI and lane cues (AUDIO_COMMISSION Batches 3-4, LP-F02) from scratch: no samples, no
recordings, no voices, no melody from anything. Every sound is built here from sine partials, filtered noise and
plucked-string models, so the files are original work of the project (COPYRIGHT_REGISTER C-280).

    uv run --with numpy,scipy,soundfile python tools/audio/synth_cues.py [--out assets/production/audio] [cue ...]

Writes <cue>.wav (48 kHz, 24-bit master, peaks at -1 dBFS) and <cue>.ogg (Vorbis, the game file) per cue.
The random seed is fixed, so a re-run gives the same files.
"""

import argparse
from pathlib import Path

import numpy as np
import soundfile as sf
from scipy import signal

SR = 48000
RNG = np.random.default_rng(1925)  # fixed: re-runs are byte-stable
PEAK = 10 ** (-1 / 20)  # -1 dBFS


def t_axis(sec: float) -> np.ndarray:
    return np.arange(int(sec * SR)) / SR


def noise(sec: float) -> np.ndarray:
    return RNG.standard_normal(int(sec * SR))


def band(x: np.ndarray, lo: float, hi: float, order: int = 2) -> np.ndarray:
    sos = signal.butter(order, [lo, hi], btype="bandpass", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def lowpass(x: np.ndarray, f: float, order: int = 2) -> np.ndarray:
    return signal.sosfilt(signal.butter(order, f, btype="lowpass", fs=SR, output="sos"), x)


def highpass(x: np.ndarray, f: float, order: int = 2) -> np.ndarray:
    return signal.sosfilt(signal.butter(order, f, btype="highpass", fs=SR, output="sos"), x)


def env_ad(n: int, attack: float, decay: float) -> np.ndarray:
    """Linear attack then exponential decay (decay = time constant, s)."""
    t = np.arange(n) / SR
    a = np.clip(t / max(attack, 1e-4), 0, 1)
    d = np.exp(-np.maximum(t - attack, 0) / decay)
    return a * d


def partials(sec: float, f0: float, ratios, amps, decays, detune: float = 0.0) -> np.ndarray:
    t = t_axis(sec)
    out = np.zeros_like(t)
    for r, a, d in zip(ratios, amps, decays):
        f = f0 * r * (1 + detune * RNG.uniform(-1, 1))
        out += a * np.sin(2 * np.pi * f * t + RNG.uniform(0, 2 * np.pi)) * np.exp(-t / d)
    return out


def fade(x: np.ndarray, fin: float = 0.002, fout: float = 0.01) -> np.ndarray:
    x = x.copy()
    i, o = int(fin * SR), int(fout * SR)
    if i:
        x[:i] *= np.linspace(0, 1, i)
    if o:
        x[-o:] *= np.linspace(1, 0, o)
    return x


def place(buf: np.ndarray, x: np.ndarray, at: float, gain: float = 1.0):
    s = int(at * SR)
    if s < 0:
        x, s = x[-s:], 0
    e = min(len(buf), s + len(x))
    if s < len(buf):
        buf[s:e] += gain * x[: e - s]


def reverb(x: np.ndarray, rt: float, wet: float, tone: float = 5000) -> np.ndarray:
    """A small room: convolution with exponentially decaying filtered noise."""
    ir = lowpass(noise(rt), tone) * np.exp(-t_axis(rt) / (rt / 6.9))
    ir /= np.sqrt(np.sum(ir**2))
    w = signal.fftconvolve(x, ir)[: len(x)]
    return (1 - wet) * x + wet * w


def norm(x: np.ndarray, peak: float = PEAK) -> np.ndarray:
    return x * (peak / max(1e-9, np.max(np.abs(x))))


# --- cues -------------------------------------------------------------------------------------------------------


def swish(sec: float, rising: bool) -> np.ndarray:
    """Cloth drawn aside: noise crossfaded from a low band to a high band (or back), soft envelope."""
    n = noise(sec)
    lo, hi = band(n, 300, 1400), band(n, 1800, 6500)
    k = np.linspace(0, 1, len(n)) ** 1.3
    if not rising:
        k = k[::-1]
    x = (1 - k) * lo * 1.6 + k * hi
    t = t_axis(sec)
    peak_at = 0.45 if rising else 0.3
    e = np.exp(-(((t / sec) - peak_at) ** 2) / 0.045)
    return fade(lowpass(x * e, 8000), 0.004, 0.03)


def ui_open():
    return swish(0.26, True)


def ui_close():
    return swish(0.2, False)


def ui_confirm():
    """A small brass bell tap: bell-like inharmonic partials, a short strike click, no long tail."""
    sec = 0.32
    x = partials(sec, 1046.5, [1, 2.0, 2.76, 4.07, 5.4], [1, 0.45, 0.35, 0.18, 0.1], [0.13, 0.08, 0.06, 0.04, 0.03])
    click = band(noise(0.006), 2000, 9000) * 0.3
    place(x, click, 0)
    return fade(x * env_ad(len(x), 0.001, 0.2), 0.0005, 0.04)


def knock(f: float) -> np.ndarray:
    sec = 0.09
    body = partials(sec, f, [1, 2.31, 4.2], [1, 0.5, 0.25], [0.018, 0.012, 0.008])
    tap = lowpass(noise(0.012), 2500) * np.exp(-t_axis(0.012) / 0.003) * 0.6
    place(body, tap, 0)
    return body


def ui_deny():
    """Two dull knocks on wood, low."""
    x = np.zeros(int(0.26 * SR))
    place(x, knock(190), 0.0)
    place(x, knock(165), 0.12, 0.85)
    return fade(lowpass(x, 3000), 0.0005, 0.02)


def ui_ready():
    """A single finger-cymbal (sagat) chime, quiet."""
    sec = 0.45
    x = partials(
        sec, 2960, [1, 1.47, 2.09, 2.68, 3.3], [1, 0.7, 0.5, 0.3, 0.2], [0.2, 0.15, 0.1, 0.08, 0.05], detune=0.002
    )
    x *= 1 + 0.15 * np.sin(2 * np.pi * 7 * t_axis(sec))  # the two plates beating
    place(x, band(noise(0.004), 4000, 12000) * 0.25, 0)
    return fade(x, 0.0005, 0.06)


def coin_jingle():
    """Abu Brahim counts the gold: six small coins clinking into a heap, quick then settling."""
    x = np.zeros(int(0.7 * SR))
    times = [0.0, 0.07, 0.12, 0.2, 0.31, 0.45]
    for i, at in enumerate(times):
        f = RNG.uniform(2600, 3600)
        c = partials(0.25, f, [1, 1.58, 2.34, 3.1], [1, 0.6, 0.4, 0.2], [0.05, 0.035, 0.025, 0.015], detune=0.01)
        c += band(noise(0.25), 5000, 12000) * np.exp(-t_axis(0.25) / 0.004) * 0.3
        place(x, c, at, 1.0 - i * 0.11)
    # the purse settling: one soft low thud under the first coin
    place(x, lowpass(noise(0.05), 400) * np.exp(-t_axis(0.05) / 0.01) * 0.5, 0.0)
    return fade(reverb(x, 0.3, 0.15), 0.0005, 0.05)


def darbuka(kind: str) -> np.ndarray:
    """doum (low centre), tek (rim), ka (other hand's rim, softer)."""
    if kind == "doum":
        sec = 0.35
        t = t_axis(sec)
        f = 95 + 60 * np.exp(-t / 0.02)  # pitch drops as the skin settles
        ph = 2 * np.pi * np.cumsum(f) / SR
        x = np.sin(ph) * np.exp(-t / 0.13) + 0.3 * np.sin(2.3 * ph) * np.exp(-t / 0.05)
        place(x, lowpass(noise(0.01), 1500) * 0.4, 0)
        return x
    sec = 0.12
    t = t_axis(sec)
    ring = partials(sec, 640 if kind == "tek" else 560, [1, 1.6, 2.7], [1, 0.5, 0.3], [0.03, 0.02, 0.012])
    crack = band(noise(sec), 2500, 8000) * np.exp(-t / 0.008)
    g = 1.0 if kind == "tek" else 0.6
    return g * (0.7 * ring + crack)


def wave_clear():
    """A short darbuka flourish: a rolling tek-ka run that lands on a doum and a closing tek."""
    x = np.zeros(int(1.3 * SR))
    at, gap = 0.0, 0.085
    for i in range(8):
        place(x, darbuka("tek" if i % 2 == 0 else "ka"), at, 0.55 + 0.05 * i)
        at += gap
        gap *= 0.9
    place(x, darbuka("doum"), at + 0.04, 1.0)
    place(x, darbuka("tek"), at + 0.3, 0.9)
    return fade(reverb(x, 0.5, 0.18), 0.001, 0.08)


def pluck(f: float, sec: float, bright: float = 0.5) -> np.ndarray:
    """Karplus-Strong string with a damped, oud-like (fretless, short sustain) colour."""
    n = int(sec * SR)
    period = int(SR / f)
    buf = lowpass(RNG.uniform(-1, 1, period), 2000 + 6000 * bright)
    out = np.zeros(n)
    loss = 0.996
    for i in range(n):
        j = i % period
        v = buf[j]
        out[i] = v
        buf[j] = loss * 0.5 * (v + buf[(j + 1) % period])
    return out


def summon_reveal():
    """A short oud strum: four courses (D2 A2 D3 G3), 22 ms apart, then the open D course rings."""
    x = np.zeros(int(1.4 * SR))
    for i, f in enumerate([73.42, 110.0, 146.83, 196.0]):
        place(x, pluck(f, 1.3, 0.55), i * 0.022, 0.9 - 0.08 * i)
    body = band(x, 90, 4500)  # the bowl's body
    return fade(reverb(body, 0.6, 0.2), 0.001, 0.15)


def rooster():
    """A rooster at dawn a rooftop away: one crow (four syllables), formant-shaped, then light room tone."""
    sec = 2.0
    segs = [  # (start, length, f_start, f_end)
        (0.05, 0.11, 520, 640),
        (0.19, 0.08, 600, 600),
        (0.30, 0.14, 640, 760),
        (0.48, 0.75, 780, 690),
    ]
    x = np.zeros(int(sec * SR))
    for st, ln, fa, fb in segs:
        t = t_axis(ln)
        f = np.linspace(fa, fb, len(t)) * (1 + 0.012 * np.sin(2 * np.pi * 9 * t))
        f *= 1 + 0.006 * RNG.standard_normal(len(t))  # roughness
        ph = 2 * np.pi * np.cumsum(f) / SR
        v = sum((0.75**k) * np.sin((k + 1) * ph) for k in range(12))
        e = np.sin(np.pi * np.clip(t / ln, 0, 1)) ** 0.6
        place(x, v * e, st)
    voiced = band(x, 700, 1300) * 1.0 + band(x, 2100, 3200) * 0.7 + band(x, 3600, 4400) * 0.3
    far = lowpass(voiced, 3800)
    far = reverb(far, 0.9, 0.45, 3000)
    room = lowpass(noise(sec), 600) * 0.012
    return fade(far + room, 0.01, 0.2)


def clash() -> np.ndarray:
    """A sword struck flat on a round shield: metallic inharmonic ring plus a crack."""
    sec = 0.6
    t = t_axis(sec)
    ring = partials(sec, 720, [1, 2.32, 3.86, 5.1, 7.3], [1, 0.8, 0.6, 0.4, 0.25], [0.25, 0.18, 0.12, 0.09, 0.05], 0.004)
    crack = band(noise(sec), 1500, 9000) * np.exp(-t / 0.012)
    return 0.6 * ring + crack


def tabl(kind: str) -> np.ndarray:
    if kind == "dum":
        sec = 0.5
        t = t_axis(sec)
        f = 58 + 35 * np.exp(-t / 0.03)
        ph = 2 * np.pi * np.cumsum(f) / SR
        x = np.sin(ph) * np.exp(-t / 0.18)
        place(x, lowpass(noise(0.015), 900) * 0.5, 0)
        return x
    sec = 0.15  # the stick on the thin skin
    t = t_axis(sec)
    return band(noise(sec), 900, 5000) * np.exp(-t / 0.02) + 0.4 * partials(sec, 330, [1, 1.7], [1, 0.4], [0.04, 0.02])


def daff() -> np.ndarray:
    sec = 0.3
    t = t_axis(sec)
    thump = partials(sec, 140, [1, 1.9], [1, 0.3], [0.06, 0.03])
    jingles = band(noise(sec), 5000, 13000) * np.exp(-t / 0.07) * (1 + 0.5 * np.sin(2 * np.pi * 31 * t))
    return 0.5 * thump + 0.5 * jingles


def arada_drums():
    """The 'arada passing by, ~75 s: tabl, daff, swords on shields on the beat. Close at first, then it moves off up
    the lane (quieter, darker, more room). Drums and steel only: no voices, no melody."""
    sec, bpm = 75.0, 104
    beat = 60 / bpm
    x = np.zeros(int(sec * SR))
    # one bar of 4: tabl D . t t | D . t . ; daff on the off-beats; a clash on 1 and 3, a double clash every 4th bar
    bar = 4 * beat
    nbars = int(sec / bar)
    for b in range(nbars):
        t0 = b * bar
        swing = RNG.uniform(-0.006, 0.006)
        for pos, k in [(0, "dum"), (1, "tak"), (1.5, "tak"), (2, "dum"), (3, "tak")]:
            place(x, tabl(k), t0 + pos * beat + swing, 0.9 if k == "dum" else 0.45)
        for pos in (0.5, 1.5, 2.5, 3.5):
            place(x, daff(), t0 + pos * beat + RNG.uniform(-0.01, 0.01), 0.35)
        place(x, clash(), t0, 0.5)
        place(x, clash(), t0 + 2 * beat, 0.45)
        if b % 4 == 3:
            place(x, clash(), t0 + 3 * beat, 0.4)
            place(x, clash(), t0 + 3.5 * beat, 0.4)
    # the procession moves away: split into chunks with falling gain, cutoff and rising room
    out = np.zeros_like(x)
    chunk = int(2.5 * SR)
    for i in range(0, len(x), chunk):
        u = i / len(x)
        g = 1.0 - 0.82 * u**0.8
        cut = 9000 - 7000 * u
        seg = lowpass(x[i : i + chunk + SR], cut)
        seg = reverb(seg, 1.2, 0.15 + 0.35 * u, 4000)
        w = np.ones(len(seg))
        xf = int(0.5 * SR)
        w[:xf] = np.linspace(0, 1, xf)
        w[-SR:] = np.linspace(1, 0, SR) if len(seg) > SR else w[-SR:]
        place(out, seg * w * g, i / SR)
    out = fade(out, 2.0, 4.0)
    out += lowpass(noise(sec), 500) * 0.004  # lane room tone so the fade-out lands on air, not silence
    return out


CUES = {
    "ui_open": ui_open,
    "ui_close": ui_close,
    "ui_confirm": ui_confirm,
    "ui_deny": ui_deny,
    "ui_ready": ui_ready,
    "wave_clear": wave_clear,
    "summon_reveal": summon_reveal,
    "rooster": rooster,
    "arada_drums": arada_drums,
    "coin_jingle": coin_jingle,
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="assets/production/audio")
    ap.add_argument("cues", nargs="*")
    a = ap.parse_args()
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    for name in a.cues or CUES:
        y = norm(CUES[name]()).astype(np.float32)
        sf.write(out / f"{name}.wav", y, SR, subtype="PCM_24")
        # libsndfile's Vorbis encoder overflows the stack on one long write: feed it one second at a time
        with sf.SoundFile(out / f"{name}.ogg", "w", SR, 1, format="OGG", subtype="VORBIS") as f:
            for i in range(0, len(y), SR):
                f.write(y[i : i + SR])
        print(f"{name}: {len(y) / SR:.2f} s, peak {20 * np.log10(np.max(np.abs(y))):.1f} dBFS")


if __name__ == "__main__":
    main()
