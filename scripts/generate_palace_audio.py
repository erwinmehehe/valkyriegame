#!/usr/bin/env python3
"""Generate original quiet PCM effects for the offline Mirror Hall."""
from pathlib import Path
import math
import struct
import wave

DESTINATION = Path(__file__).resolve().parents[1] / 'ValkyrieLearn/Resources'
RATE = 24000

def write(name, duration, signal):
    samples = []
    for index in range(int(RATE * duration)):
        time = index / RATE
        # Smooth the ends; ambience joins at silence to avoid a loop click.
        edge = min(1, time / 0.025, (duration - time) / 0.08)
        value = max(-1, min(1, signal(time) * edge))
        samples.append(struct.pack('<h', round(value * 32767)))
    with wave.open(str(DESTINATION / (name + '.wav')), 'wb') as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(b''.join(samples))

write('mirror_click', 0.22, lambda t: math.exp(-t * 25) * (
    0.22 * math.sin(2 * math.pi * 890 * t) + 0.08 * math.sin(2 * math.pi * 1440 * t)))
write('mirror_turn', 0.7, lambda t: math.sin(math.pi * t / 0.7) ** 2 * (
    0.12 * math.sin(2 * math.pi * (240 * t + 100 * t * t))
    + 0.035 * math.sin(2 * math.pi * 720 * t)))
write('palace_ambience', 8, lambda t: math.sin(math.pi * t / 8) ** 2 * (
    0.08 * math.sin(2 * math.pi * 144 * t)
    + 0.04 * math.sin(2 * math.pi * 216 * t)
    + 0.025 * math.sin(2 * math.pi * 360 * t)))
print('Generated three original Mirror Hall audio clips.')
