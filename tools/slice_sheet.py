"""Quita el fondo blanco de una hoja de sprites y separa cada figura.
Uso: python slice_sheet.py <imagen> <carpeta_salida> <preview.png>
Guarda sprite_NN.png (recortes con transparencia) y un preview con los números."""
import sys, os
from collections import deque
import numpy as np
from PIL import Image, ImageDraw

src, out, prev = sys.argv[1], sys.argv[2], sys.argv[3]
os.makedirs(out, exist_ok=True)
im = Image.open(src).convert('RGB')
a = np.asarray(im).astype(np.int16)
H, W, _ = a.shape
mx, mn = a.max(axis=2), a.min(axis=2)
bgish = (mn > 225) & ((mx - mn) < 18)            # blanco/gris muy claro sin color
# flood fill desde los bordes sobre los pixeles tipo fondo
bg = np.zeros((H, W), bool)
q = deque()
for x in range(W):
    for y in (0, H - 1):
        if bgish[y, x] and not bg[y, x]:
            bg[y, x] = True; q.append((y, x))
for y in range(H):
    for x in (0, W - 1):
        if bgish[y, x] and not bg[y, x]:
            bg[y, x] = True; q.append((y, x))
while q:
    y, x = q.popleft()
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        ny, nx = y + dy, x + dx
        if 0 <= ny < H and 0 <= nx < W and not bg[ny, nx] and bgish[ny, nx]:
            bg[ny, nx] = True; q.append((ny, nx))
fg = ~bg
# componentes conectados (8 vecinos)
lab = np.zeros((H, W), np.int32)
boxes = []
cur = 0
for y in range(H):
    for x in range(W):
        if fg[y, x] and lab[y, x] == 0:
            cur += 1
            q = deque([(y, x)]); lab[y, x] = cur
            x0 = x1 = x; y0 = y1 = y; n = 0
            while q:
                cy, cx = q.popleft(); n += 1
                x0, x1, y0, y1 = min(x0, cx), max(x1, cx), min(y0, cy), max(y1, cy)
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        ny, nx = cy + dy, cx + dx
                        if 0 <= ny < H and 0 <= nx < W and fg[ny, nx] and lab[ny, nx] == 0:
                            lab[ny, nx] = cur; q.append((ny, nx))
            boxes.append([x0, y0, x1, y1, n])
# quitar ruido y unir piezas cercanas (p. ej. un puntero o chispas)
boxes = [b for b in boxes if b[4] > 60]
merged = True
while merged:
    merged = False
    for i in range(len(boxes)):
        for j in range(i + 1, len(boxes)):
            A, B = boxes[i], boxes[j]
            gap = 6
            if A[0] - gap <= B[2] and B[0] - gap <= A[2] and A[1] - gap <= B[3] and B[1] - gap <= A[3]:
                small = min(A[4], B[4])
                if small < 2500:
                    boxes[i] = [min(A[0], B[0]), min(A[1], B[1]), max(A[2], B[2]), max(A[3], B[3]), A[4] + B[4]]
                    boxes.pop(j); merged = True
                    break
        if merged:
            break
boxes = [b for b in boxes if b[4] > 1500]
# ordenar por filas (centro y), luego x
boxes.sort(key=lambda b: (round(((b[1] + b[3]) / 2) / 60), b[0]))
rgba = np.dstack([np.asarray(im), (fg * 255).astype(np.uint8)])
full = Image.fromarray(rgba, 'RGBA')
pv = im.copy().convert('RGB')
d = ImageDraw.Draw(pv)
for i, (x0, y0, x1, y1, n) in enumerate(boxes):
    full.crop((x0, y0, x1 + 1, y1 + 1)).save(os.path.join(out, 'sprite_%02d.png' % i))
    d.rectangle([x0, y0, x1, y1], outline=(255, 0, 0), width=2)
    d.text((x0 + 3, y0 + 3), str(i), fill=(255, 0, 0))
pv.resize((W * 3 // 4, H * 3 // 4)).save(prev)
for i, b in enumerate(boxes):
    print(i, b)
