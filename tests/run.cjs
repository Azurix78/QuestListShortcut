const fs = require('node:fs');
const path = require('node:path');

function run() {
  const results = [];
  const log = message => { results.push(message); console.log(message); };
  const parser = require('luaparse');
  const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');
  const root = path.resolve(__dirname, '..');
  for (const file of ['QuestListShortcut/Localization.lua', 'QuestListShortcut/Core.lua', 'QuestListShortcut/ZoneTracking.lua', 'tests/run.lua']) {
    parser.parse(fs.readFileSync(path.join(root, file), 'utf8'), { luaVersion: '5.1' });
    log('Lua 5.1 syntax OK: ' + file);
  }
  const state = lauxlib.luaL_newstate();
  try {
    lualib.luaL_openlibs(state);
    lua.lua_pushcfunction(state, luaState => {
      log(to_jsstring(lua.lua_tostring(luaState, 1)));
      return 0;
    });
    lua.lua_setglobal(state, to_luastring('print'));
    lua.lua_pushstring(state, to_luastring(root.replaceAll('\\', '/')));
    lua.lua_setglobal(state, to_luastring('TEST_ROOT'));
    lua.lua_pushstring(state, to_luastring(fs.readFileSync(path.join(root, 'QuestListShortcut/QuestListShortcut.toc'), 'utf8')));
    lua.lua_setglobal(state, to_luastring('TEST_TOC'));
    const source = fs.readFileSync(path.join(__dirname, 'run.lua'), 'utf8');
    if (lauxlib.luaL_dostring(state, to_luastring(source)) !== lua.LUA_OK) {
      throw new Error(to_jsstring(lua.lua_tostring(state, -1)));
    }
  } finally {
    lua.lua_close(state);
  }
  return results;
}

if (require.main === module) run();
module.exports = run;
