// Read-only fixture handoff: strict JSON parsing in Node, production flow in Lua.
const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const root = path.resolve(__dirname, '..');
const raw = fs.readFileSync(path.join(root, 'data/stores.json'), 'utf8');
const state = JSON.parse(raw);
function lua(value) {
  if (value === null) return 'nil';
  if (typeof value === 'string') return JSON.stringify(value).replace(/\\u([0-9a-f]{4})/gi, (_, hex) => `\\u{${hex}}`);
  if (typeof value !== 'object') return String(value);
  if (Array.isArray(value)) return `{${value.map(lua).join(',')}}`;
  return `{${Object.entries(value).map(([key, item]) => `[${lua(key)}]=${lua(item)}`).join(',')}}`;
}
const result = spawnSync(process.argv[2] || 'E:/[BASE-DE-CONHECIMENTO]/LUAC/lua55.exe',
  ['tests/stores_json_integration.lua'], { cwd: root, input: `return ${lua(state)}`, encoding: 'utf8' });
process.stdout.write(result.stdout || '');
process.stderr.write(result.stderr || '');
if (result.error) throw result.error;
if (fs.readFileSync(path.join(root, 'data/stores.json'), 'utf8') !== raw) throw new Error('Production JSON was modified');
process.exitCode = result.status ?? 1;
