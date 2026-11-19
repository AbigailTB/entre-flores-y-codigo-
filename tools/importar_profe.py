"""Importa la hoja de sprites de un profe (mismo acomodo que la de Juvencio) al juego.
Uso:  python tools/importar_profe.py <imagen_hoja> <id_profe>
      ej. python tools/importar_profe.py "D:/hojas/luis.webp" luis
Crea assets/sprites/teachers/<id>/ (caminar, de lado, espalda, poses y caras) y
actualiza su retrato. El juego lo detecta solo: el profe camina y cambia de cara.
"""
import sys, os, subprocess, tempfile, shutil
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
img, tid = sys.argv[1], sys.argv[2]
tmp = tempfile.mkdtemp()
out = subprocess.run([sys.executable, os.path.join(HERE, 'slice_sheet.py'), img, tmp, os.path.join(tmp, 'preview.png')],
                     capture_output=True, text=True)
boxes = [l.split(' ', 1) for l in out.stdout.strip().splitlines() if l[:1].isdigit()]
preview = os.path.join(tmp, 'preview.png')
info = []
for idx, rest in boxes:
    x0, y0, x1, y1, n = eval(rest)
    info.append((int(idx), x0, y0, x1, y1, n))

def group_rows(items):
    """Agrupa por filas (de arriba a abajo) y ordena cada fila de izquierda a derecha."""
    items = sorted(items, key=lambda b: (b[2] + b[4]) / 2)
    rows, cur, last = [], [], None
    for b in items:
        cy = (b[2] + b[4]) / 2
        if last is not None and cy - last > 80:
            rows.append(cur); cur = []
        cur.append(b); last = cy
    rows.append(cur)
    return [sorted(r, key=lambda b: b[1]) for r in rows]

M = {}
rows = group_rows(info)
sizes = [len(r) for r in rows]
if sizes == [6, 6, 6, 6, 6, 6]:
    # Acomodo NUEVO: cuadrícula pareja de 6 x 6
    names = [['face_normal', 'face_happy', 'face_wink', 'face_surprised', 'face_serious', 'face_angry'],
             ['walk_%d' % i for i in range(1, 7)],
             ['idle_side_1', 'idle_side_2', 'back_1', 'back_2', 'back_3', 'back_4'],
             ['pose_lentes', 'pose_saludo', 'pose_puntero', 'pose_tablet', 'pose_pensando', 'pose_brazos'],
             ['hero', 'pose_libros', 'pose_escritorio', 'pose_pizarron', 'pose_mochila_1', 'pose_mochila_2'],
             ['face_laugh', 'face_smile', 'face_glasses', 'face_mad', 'face_thinking', 'face_talk']]
    for r, row in enumerate(rows):
        for b, name in zip(row, names[r]):
            M[b[0]] = name
elif len(info) == 38:
    # Acomodo ANTERIOR (Juvencio, Yuls, Luis): figura grande + filas de 7, 7, 7, 7 y 9
    hero = max(info, key=lambda b: (b[3] - b[1]) * (b[4] - b[2]))
    rows = group_rows([b for b in info if b is not hero])
    sizes = [len(r) for r in rows]
    if sizes != [7, 7, 7, 7, 9]:
        print('Las filas no coinciden con el acomodo esperado (7,7,7,7,9): %s. Revisa: %s' % (sizes, preview))
        sys.exit(1)
    names = [['face_normal', 'face_happy', 'face_wink', 'face_surprised', 'face_serious', 'face_angry', 'face_thinking'],
             ['walk_%d' % i for i in range(1, 8)],
             ['idle_side_1', 'idle_side_2', 'idle_side_3', 'back_1', 'back_2', 'back_3', 'back_4'],
             ['pose_lentes', 'pose_saludo', 'pose_puntero', 'pose_tablet', 'pose_pensando', 'pose_brazos', 'pose_libros'],
             ['pose_escritorio', 'pose_pizarron', 'pose_tablet2', 'pose_mochila_1', 'pose_mochila_2',
              'face_laugh', 'face_smile', 'face_glasses', 'face_mad']]
    M[hero[0]] = 'hero'
    for r, row in enumerate(rows):
        for b, name in zip(row, names[r]):
            M[b[0]] = name
else:
    print('La hoja tiene %d figuras en filas %s. Se esperaba una cuadrícula de 6x6 (36) o el acomodo de Juvencio (38). Revisa: %s'
          % (len(info), sizes, preview))
    sys.exit(1)
dst = os.path.join(ROOT, 'assets/sprites/teachers', tid)
os.makedirs(dst, exist_ok=True)
body = [k for k, v in M.items() if v.startswith(('walk_', 'idle_side_', 'back_'))]
ims = {k: Image.open(os.path.join(tmp, 'sprite_%02d.png' % k)) for k in M}
CW = max(ims[k].width for k in body) + 8
CH = max(ims[k].height for k in body) + 4
for k, name in M.items():
    im = ims[k]
    if k in body:
        c = Image.new('RGBA', (CW, CH), (0, 0, 0, 0))
        c.alpha_composite(im, ((CW - im.width) // 2, CH - 2 - im.height))
        im = c
    im.save(os.path.join(dst, name + '.png'))
shutil.copy(os.path.join(dst, 'face_normal.png'), os.path.join(ROOT, 'assets/portraits', tid + '.png'))
print('Listo: %s (%d archivos)' % (dst, len(M)))
