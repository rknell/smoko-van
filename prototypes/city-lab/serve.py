"""Serve only the Godot web export; localhost by default."""
import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--lan', action='store_true', help='Allow devices on the local network')
parser.add_argument('--port', type=int, default=4174)
args = parser.parse_args()
root = Path(__file__).resolve().parent / 'build' / 'web'
if not (root / 'index.html').exists():
    parser.error('Export the Web preset first; build/web/index.html is missing.')
handler = partial(SimpleHTTPRequestHandler, directory=str(root))
address = '0.0.0.0' if args.lan else '127.0.0.1'
print(f'City Lab: http://{address}:{args.port}', flush=True)
ThreadingHTTPServer((address, args.port), handler).serve_forever()
