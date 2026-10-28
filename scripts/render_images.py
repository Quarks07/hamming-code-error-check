"""Render the simulator's VCD and console output as PNG files. Requires Pillow."""
from pathlib import Path
import re
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
FONT = Path('C:/Windows/Fonts/consola.ttf')
if not FONT.exists():
    FONT = Path('/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf')


def font(size):
    return ImageFont.truetype(str(FONT), size)


BG, FG, MUTED, GRID = '#111827', '#e5e7eb', '#9ca3af', '#334155'
GREEN, BLUE, ORANGE = '#86efac', '#93c5fd', '#fdba74'


def canvas(width, height, title, subtitle):
    image = Image.new('RGB', (width, height), BG)
    draw = ImageDraw.Draw(image)
    draw.text((32, 24), title, font=font(30), fill=FG)
    draw.text((32, 70), subtitle, font=font(18), fill=MUTED)
    return image, draw


# Read top-level signals and their actual value changes from the VCD.
variables, events, scope = {}, {}, []
time, definitions = 0, True
vcd = (ROOT / 'sim/waveform.vcd').read_text()
assert re.search(r'\$timescale\s+1ps\s+\$end', vcd), 'Expected a 1 ps VCD'
for line in vcd.splitlines():
    parts = line.split()
    if not parts:
        continue
    if definitions:
        if parts[0] == '$scope':
            scope.append(parts[2])
        elif parts[0] == '$upscope':
            scope.pop()
        elif parts[0] == '$var' and scope == ['tb_hamming74']:
            variables[parts[4]] = (parts[3], int(parts[2]))
            events.setdefault(parts[3], [])
        elif parts[0] == '$enddefinitions':
            definitions = False
    elif line.startswith('#'):
        time = int(line[1:]) / 1000  # ps to ns
    elif line.startswith('b'):
        value, code = parts[0][1:], parts[1]
        if code in events:
            events[code].append((time, value))
    elif line[0] in '01xz':
        code = line[1:]
        if code in events:
            events[code].append((time, line[0]))


def value_at(name, t):
    code, width = variables[name]
    value = 'x'
    for change_time, new_value in events[code]:
        if change_time > t:
            break
        value = new_value
    return value.zfill(width)


# Confirm that the plotted window contains the intended directed tests.
for position in range(8):
    t = position * 10 + 5
    assert value_at('data_out', t) == '1011'
    assert int(value_at('syndrome', t), 2) == position
assert value_at('data_out', 95) == '0011'

image, draw = canvas(1800, 900, 'Hamming (7,4) waveform',
                     'Vivado Simulator 2026.1 | actual VCD values | directed tests, 0 to 100 ns')
left, right, top, row = 270, 1760, 220, 65
step = (right - left) / 10
labels = ['clean', 'bit 1', 'bit 2', 'bit 3', 'bit 4', 'bit 5', 'bit 6', 'bit 7', 'clean', 'bits 1+3']
for i, label in enumerate(labels):
    x = left + step * (i + .5)
    draw.text((x, 135), label, anchor='mm', font=font(18), fill=ORANGE if i == 9 else MUTED)
for i in range(11):
    x = left + step * i
    draw.line((x, 180, x, 770), fill=GRID)
    draw.text((x, 193), str(i * 10), anchor='mm', font=font(18), fill=MUTED)
draw.text((left - 55, 193), 'ns', font=font(18), fill=MUTED)

signals = ['data_in', 'error_mask', 'encoded', 'received', 'syndrome', 'error_detected', 'corrected', 'data_out']
for index, name in enumerate(signals):
    y = top + index * row
    draw.text((32, y + 22), name, font=font(23), fill=FG)
    color = GREEN if name in ('corrected', 'data_out') else BLUE
    if name == 'error_detected':
        points = []
        for i in range(10):
            level = y + (10 if value_at(name, i * 10 + 5) == '1' else 45)
            points.extend([(left + i * step, level), (left + (i + 1) * step, level)])
        draw.line(points, fill=color, width=3)
        continue
    start = 0
    for i in range(1, 11):
        if i < 10 and value_at(name, i * 10 + 5) == value_at(name, start * 10 + 5):
            continue
        x0, x1 = left + start * step, left + i * step
        cell_color = ORANGE if start == 9 else color
        draw.line([(x0, y+28), (x0+5, y+8), (x1-5, y+8), (x1, y+28),
                   (x1-5, y+48), (x0+5, y+48), (x0, y+28)], fill=cell_color, width=2)
        draw.text(((x0+x1)/2, y+28), value_at(name, start*10+5),
                  anchor='mm', font=font(20), fill=cell_color)
        start = i

draw.text((32, 800), 'Single-bit faults: data_out stays 1011. Two-bit fault at 90 ns: data_out becomes 0011.',
          font=font(22), fill=FG)
draw.text((32, 843), 'Source: sim/waveform.vcd. Testbench delays show test cases, not hardware propagation time.',
          font=font(18), fill=MUTED)
image.save(ROOT / 'images/waveform.png')

log = (ROOT / 'sim/simulation.log').read_text()
begin = log.index('Hamming (7,4) - even parity')
end = log.index('ALL TESTS PASSED', begin) + len('ALL TESTS PASSED')
transcript = log[begin:end]
(ROOT / 'sim/output.txt').write_text(transcript + '\n')
lines = transcript.splitlines()
image, draw = canvas(1520, 160 + 35 * len(lines), 'Simulation output',
                     'Vivado Simulator 2026.1 | excerpt from sim/simulation.log')
for i, line in enumerate(lines):
    color = GREEN if line.startswith(('PASS', 'ALL TESTS')) else FG
    draw.text((32, 125 + i * 35), line, font=font(22), fill=color)
image.save(ROOT / 'images/output.png')
print('Saved images/waveform.png and images/output.png from VCD and simulator log.')
