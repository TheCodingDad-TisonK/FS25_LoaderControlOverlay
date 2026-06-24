// Lua syntax smoke-test using fengari (borrowed from the FS25_SoilFertilizer
// test harness). Compiles every src/**.lua with luaL_loadstring and reports
// syntax errors. Run:  node tools/check_lua.cjs
const fs = require("fs");
const path = require("path");

const FENGARI = "C:/Users/tison/Desktop/FS25 MODS/FS25_SoilFertilizer/tools/test/node_modules/fengari/src/fengari.js";
const fengari = require(FENGARI);
const { lua, lauxlib, to_luastring } = fengari;

const ROOT = path.resolve(__dirname, "..");
const SRC = path.join(ROOT, "src");

function findLua(dir) {
  const out = [];
  for (const e of fs.readdirSync(dir)) {
    const full = path.join(dir, e);
    const st = fs.statSync(full);
    if (st.isDirectory()) out.push(...findLua(full));
    else if (e.endsWith(".lua")) out.push(full);
  }
  return out.sort();
}

let failed = 0;
for (const file of findLua(SRC)) {
  const code = fs.readFileSync(file, "utf8");
  const L = lauxlib.luaL_newstate();
  const status = lauxlib.luaL_loadstring(L, to_luastring(code));
  const relPath = path.relative(ROOT, file).replace(/\\/g, "/");
  if (status !== lua.LUA_OK) {
    const err = lua.lua_tojsstring(L, -1);
    console.log("FAIL  " + relPath + "\n      " + err);
    failed++;
  } else {
    console.log("ok    " + relPath);
  }
}
console.log(failed === 0 ? "\nAll files compiled." : `\n${failed} file(s) FAILED.`);
process.exit(failed === 0 ? 0 : 1);
