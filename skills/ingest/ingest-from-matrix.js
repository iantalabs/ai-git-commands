#!/usr/bin/env node
/*
 * ingest-from-matrix.js — ingest the last link posted in a Matrix room into a
 * desk skill spreadsheet, and answer in that message's thread.
 *
 * The operator drops a link in a room (AI-Tech first); Claude runs `/ingest`,
 * which runs this. It drives the SAME editor-server endpoints the desk's
 * YouTube panel uses — /api/skills/youtube/metadata, then generate-with-frames —
 * so a room-driven ingest and a click-driven one produce identical skills, and
 * every fix to the ingester applies to both.
 *
 * v1 scope (todo #26 is v2): YouTube links only, a fixed frame interval
 * (default 10s), the video's own title, auto-sections exactly when the server
 * recommends them (the panel's default too).
 *
 * Usage:
 *   node ingest-from-matrix.js --room AI-Tech            # ingest + reply in thread
 *   node ingest-from-matrix.js --room AI-Tech --dry-run  # show what it would ingest
 *   node ingest-from-matrix.js --room AI-Tech --interval 5 --no-post
 *   node ingest-from-matrix.js --room AI-Tech --url <youtube url>   # a specific link, answered in the room
 *   node ingest-from-matrix.js --url <youtube url>       # a link with no room: nothing is posted
 *   add --force to ingest a video the desk already has
 *
 * Needs the editor-server on :3005 (`aidesk start`). Rooms must be unencrypted:
 * this speaks the plain client-server API. A pending invite to the named room is
 * accepted on the way (unencrypted rooms only), so a new room needs no extra step.
 *
 * CREDENTIALS are Claude's Matrix account (@claude), not the desk bot's: the
 * operator invites "you" — the account /post and /look already use — so the
 * replies come from the same identity as every other Claude post. Read by
 * reference from ~/.claude/matrix-post.json → `secrets_from`, as matrix-post
 * does; INGEST_MATRIX_SECRETS overrides. The desk bot (@3aidesk, in
 * editor-server/secrets/matrix.json) is a different user and is NOT in the room.
 */

'use strict';

const fs = require('fs');
const path = require('path');

// Lives in ai-git-commands (skills/ingest/), not in 3aidesk: the desk checkout may be on
// any branch, and a skill that exists on one branch only vanished on the others.
const REPO = process.env.AIDESK_DIR || path.join(require('os').homedir(), 'workspace', 'iantalabs', '3aidesk');
const SKILLS_DIR = path.join(REPO, 'site', 'content', 'skills');
const MEDIA_SKILLS_DIR = path.join(process.env.MEDIA_DIR || '/Volumes/L256/il30mar26', 'skills');
const EDITOR = process.env.EDITOR_SERVER || 'http://localhost:3005';
const DESK = process.env.DESK_URL || 'http://localhost:1314';
// Cloudflare fronts saltm.w3ai.org and 403s (error 1010) a request without a
// User-Agent, which is what node's fetch sends by default (ncol matrix-post).
const USER_AGENT = '3aidesk-ingest/1.0 (+https://github.com/iantalabs/3aidesk)';

const args = process.argv.slice(2);
const flag = (n, d) => { const i = args.indexOf('--' + n); return i >= 0 && args[i + 1] && !args[i + 1].startsWith('--') ? args[i + 1] : d; };
// --url alone ingests a link without a room (nothing posted); otherwise AI-Tech is the default room.
const ROOM = flag('room', args.includes('--url') ? null : 'AI-Tech');
const INTERVAL = Number(flag('interval', 10));
const URL_OVERRIDE = flag('url', null);
const DRY = args.includes('--dry-run');
const POST = !args.includes('--no-post') && !DRY && !!ROOM;
const FORCE = args.includes('--force');

const YT_RE = /https?:\/\/(?:www\.|m\.)?(?:youtube\.com\/(?:watch\?[^\s<>"]*v=|shorts\/|live\/)|youtu\.be\/)([A-Za-z0-9_-]{11})[^\s<>")\]]*/;
const ANY_URL_RE = /https?:\/\/[^\s<>")\]]+/;

// ── Matrix ──────────────────────────────────────────────────────────────────

function secretsPath() {
  if (process.env.INGEST_MATRIX_SECRETS) return process.env.INGEST_MATRIX_SECRETS;
  const home = require('os').homedir();
  const cfg = JSON.parse(fs.readFileSync(path.join(home, '.claude', 'matrix-post.json'), 'utf8'));
  return String(cfg.secrets_from).replace(/^~(?=\/)/, home);
}
const secrets = JSON.parse(fs.readFileSync(secretsPath(), 'utf8'));

async function mx(method, p, body) {
  // Retry a dropped connection (a bare "fetch failed" on the first run, 2026-09-29),
  // never an HTTP answer: a 403 or 404 means something and must surface.
  let res;
  for (let attempt = 1; ; attempt++) {
    try {
      res = await fetch(secrets.homeserver_url + p, {
        method,
        headers: { Authorization: `Bearer ${secrets.access_token}`, 'User-Agent': USER_AGENT, 'Content-Type': 'application/json' },
        body: body ? JSON.stringify(body) : undefined,
      });
      break;
    } catch (err) {
      if (attempt >= 3) throw err;
      await new Promise(r => setTimeout(r, 1000 * attempt));
    }
  }
  const text = await res.text();
  if (!res.ok) throw new Error(`matrix ${method} ${p.split('?')[0]} → ${res.status}: ${text.slice(0, 200)}`);
  return text ? JSON.parse(text) : {};
}

/**
 * Accept a pending invite to the room the operator named, so "I invited you to
 * SI Fit — ingest from it" is one step. Only that room, and only if the invite
 * shows it unencrypted: this client holds no keys, and joining an encrypted room
 * would only produce messages it cannot read.
 */
async function acceptInvite(name) {
  const filter = { room: { timeline: { limit: 0 }, state: { types: ['m.room.name'] } }, presence: { types: [] }, account_data: { types: [] } };
  const sync = await mx('GET', `/_matrix/client/v3/sync?timeout=0&filter=${encodeURIComponent(JSON.stringify(filter))}`);
  for (const [id, r] of Object.entries((sync.rooms && sync.rooms.invite) || {})) {
    const ev = (r.invite_state && r.invite_state.events) || [];
    const rn = ((ev.find(e => e.type === 'm.room.name') || {}).content || {}).name || '';
    if (rn.toLowerCase() !== name.toLowerCase()) continue;
    if (ev.some(e => e.type === 'm.room.encryption')) throw new Error(`the invite to "${rn}" is for an encrypted room — not joining`);
    await mx('POST', `/_matrix/client/v3/join/${encodeURIComponent(id)}`, {});
    console.log(`[ingest] accepted the invite to "${rn}" (${id})`);
    return { id, name: rn };
  }
  return null;
}

/** A room id passes straight through; a name must match exactly one joined room. */
async function resolveRoom(nameOrId) {
  if (nameOrId.startsWith('!')) return { id: nameOrId, name: nameOrId };
  const { joined_rooms } = await mx('GET', '/_matrix/client/v3/joined_rooms');
  const hits = [];
  for (const id of joined_rooms) {
    const r = await mx('GET', `/_matrix/client/v3/rooms/${encodeURIComponent(id)}/state/m.room.name`).catch(() => ({}));
    if ((r.name || '').toLowerCase() === nameOrId.toLowerCase()) hits.push({ id, name: r.name });
  }
  if (!hits.length) {
    const joined = await acceptInvite(nameOrId);
    if (joined) hits.push(joined);
  }
  if (hits.length !== 1) {
    throw new Error(hits.length
      ? `${hits.length} joined rooms are named "${nameOrId}" — pass the room id instead`
      : `${secrets.user_id} is not in a room named "${nameOrId}" and has no invite to one — invite it first`);
  }
  const enc = await fetch(`${secrets.homeserver_url}/_matrix/client/v3/rooms/${encodeURIComponent(hits[0].id)}/state/m.room.encryption`,
    { headers: { Authorization: `Bearer ${secrets.access_token}`, 'User-Agent': USER_AGENT } });
  if (enc.status === 200) throw new Error(`room "${nameOrId}" is encrypted — this reads the plain API only`);
  return hits[0];
}

/**
 * The newest message carrying a YouTube link, not sent by the bot — its own
 * replies carry desk links, and "the last link" must mean the operator's.
 * Newer non-YouTube links are skipped but returned, so the reply can say so:
 * "ingest latest YT from SI Fit" should not stop at an article posted after it.
 */
async function lastLink(roomId) {
  let from = '';
  const skipped = [];
  for (let page = 0; page < 5; page++) {
    const r = await mx('GET', `/_matrix/client/v3/rooms/${encodeURIComponent(roomId)}/messages?dir=b&limit=50${from ? '&from=' + encodeURIComponent(from) : ''}`);
    for (const e of r.chunk || []) {
      if (e.type !== 'm.room.message' || e.sender === secrets.user_id) continue;
      const body = String((e.content && e.content.body) || '');
      const yt = YT_RE.exec(body);
      if (yt) return { event: e, url: yt[0], yt, skipped };
      const any = ANY_URL_RE.exec(body);
      if (any) skipped.push(any[0]);
    }
    if (!r.end || !(r.chunk || []).length) break;
    from = r.end;
  }
  return skipped.length ? { skipped } : null;
}

const txnId = () => `${Date.now()}-${process.pid}-${Math.random().toString(16).slice(2, 8)}`;

/** Reply in the thread rooted at `rootId`. html is optional, body is the plain fallback. */
async function reply(roomId, rootId, body, html) {
  if (!POST) { console.log(ROOM ? `\n[would post in thread]\n${body}` : `[ingest] ${body}`); return; }
  const content = { msgtype: 'm.text', body };
  if (html) Object.assign(content, { format: 'org.matrix.custom.html', formatted_body: html });
  if (rootId) content['m.relates_to'] = { rel_type: 'm.thread', event_id: rootId, is_falling_back: true };
  await mx('PUT', `/_matrix/client/v3/rooms/${encodeURIComponent(roomId)}/send/m.room.message/${txnId()}`, content);
}

const esc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

// ── Desk ────────────────────────────────────────────────────────────────────

/**
 * Skills already ingested from this video: by the videoId in this checkout's front
 * matter, AND by the source.json marker in each media dir on L256, which every branch
 * shares — the checkout alone missed skills on other branches (2026-09-30).
 */
function existingSkills(videoId) {
  const found = new Set();
  const scan = (dir, file, match) => {
    try {
      for (const d of fs.readdirSync(dir)) {
        const f = path.join(dir, d, file);
        try { if (match(fs.readFileSync(f, 'utf8'))) found.add(d); } catch { /* no such file */ }
      }
    } catch { /* no such dir */ }
  };
  scan(SKILLS_DIR, '_index.md', t => t.includes(`videoId: "${videoId}"`));
  scan(MEDIA_SKILLS_DIR, 'source.json', t => { try { return JSON.parse(t).id === videoId; } catch { return false; } });
  return [...found].sort((a, b) => parseInt(a.slice(5), 10) - parseInt(b.slice(5), 10));
}

async function editorUp() {
  try { await fetch(EDITOR + '/api/skills/active-jobs', { signal: AbortSignal.timeout(3000) }); return true; } catch { return false; }
}

async function postJson(p, body) {
  const res = await fetch(EDITOR + p, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
  const data = await res.json().catch(() => ({}));
  if (!res.ok || data.error) throw new Error(data.error || `${p} → HTTP ${res.status}`);
  return data;
}

/** Run generate-with-frames, printing its SSE progress; resolves with the 'done' event. */
async function generate(body) {
  const res = await fetch(EDITOR + '/api/skills/youtube/generate-with-frames', {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`generate-with-frames → HTTP ${res.status}: ${(await res.text()).slice(0, 200)}`);
  const decoder = new TextDecoder();
  let buf = '', done = null, skeleton = null;
  const rowErrors = [];
  for await (const chunk of res.body) {
    buf += decoder.decode(chunk, { stream: true });
    let i;
    while ((i = buf.indexOf('\n\n')) >= 0) {
      const line = buf.slice(0, i).replace(/^data: /, ''); buf = buf.slice(i + 2);
      if (!line.trim()) continue;
      let evt; try { evt = JSON.parse(line); } catch { continue; }
      if (evt.type === 'skeleton_ready') { skeleton = evt; console.log(`[ingest] skeleton ${evt.skillId} (${evt.totalRows} rows)`); }
      else if (evt.type === 'download_start' || evt.type === 'download_done') console.log(`[ingest] ${evt.message}`);
      else if (evt.type === 'row_done') console.log(`[ingest] row ${evt.row}/${evt.totalRows} done — ${evt.title || ''}`);
      else if (evt.type === 'chapter_error') { rowErrors.push(`row ${evt.row}: ${evt.error}`); console.error(`[ingest] row ${evt.row} error: ${evt.error}`); }
      else if (evt.type === 'error') { const e = new Error(evt.error); e.skeleton = skeleton; throw e; }
      else if (evt.type === 'done') done = evt;
    }
  }
  if (!done) throw new Error('the ingest stream ended without a done event');
  return { ...done, rowErrors };
}

// ── Main ────────────────────────────────────────────────────────────────────

(async () => {
  const room = ROOM ? await resolveRoom(ROOM) : { id: null, name: '(no room)' };
  let root = null, url = URL_OVERRIDE, videoId = null;

  if (!URL_OVERRIDE) {
    const hit = await lastLink(room.id);
    if (!hit) throw new Error(`no link in the last 250 messages of "${room.name}"`);
    if (!hit.event) {
      throw new Error(`no YouTube link in the last 250 messages of "${room.name}" — /ingest v1 handles YouTube only`
        + ` (newest other link: ${hit.skipped[0]})`);
    }
    root = hit.event;
    const when = new Date(root.origin_server_ts).toISOString().replace('T', ' ').slice(0, 16);
    console.log(`[ingest] latest YouTube link in ${room.name}: ${hit.url}  (${root.sender}, ${when} UTC)`);
    if (hit.skipped.length) console.log(`[ingest] skipped ${hit.skipped.length} newer non-YouTube link(s): ${hit.skipped.slice(0, 3).join(' · ')}`);
    url = hit.yt[0]; videoId = hit.yt[1];
  } else {
    const m = YT_RE.exec(URL_OVERRIDE);
    if (!m) throw new Error(`--url ${URL_OVERRIDE} is not a YouTube link`);
    videoId = m[1];
  }

  const already = existingSkills(videoId);
  if (already.length && !FORCE) {
    const links = already.map(s => `${DESK}/skills/${s}/`).join(' · ');
    const msg = `Already on the desk: ${links}. Not ingested again (pass --force to make another copy).`;
    console.error('[ingest] ' + msg);
    await reply(room.id, root && root.event_id, msg);
    process.exit(3);
  }

  if (!(await editorUp())) throw new Error(`the editor-server is not answering on ${EDITOR} — run \`aidesk start\``);

  console.log('[ingest] fetching video details (title, chapters, transcript)…');
  const meta = await postJson('/api/skills/youtube/metadata', { url });
  // Same choice the desk panel makes by default: synthetic sections when the
  // server recommends them, re-cut from the real chapters' transcript.
  let metadata = meta;
  const synthetic = !!(meta.useAutoSections && (meta.autoSections || []).length);
  if (synthetic) {
    const segs = (meta.chapters || []).flatMap(ch => ch.transcript || []);
    metadata = { ...meta, chapters: meta.autoSections.map(sec => ({ ...sec, transcript: segs.filter(s => s.start < sec.endTime && s.end > sec.startTime) })) };
  }
  const mins = `${Math.floor(meta.duration / 60)}:${String(Math.round(meta.duration % 60)).padStart(2, '0')}`;
  const plan = `"${meta.title}" · ${mins} · ${metadata.chapters.length} ${synthetic ? 'auto-sections' : 'chapters'} · a frame every ${INTERVAL}s (~${Math.ceil(meta.duration / INTERVAL)} frames)`;
  console.log('[ingest] ' + plan);

  if (DRY) { console.log('\nDRY RUN — nothing ingested, nothing posted.'); return; }

  await reply(room.id, root && root.event_id, `Ingesting ${plan} …`);
  const t0 = Date.now();
  let r;
  try {
    r = await generate({ videoUrl: url, metadata, intervalSec: INTERVAL, skillTitle: meta.title });
  } catch (err) {
    const msg = `Ingest failed: ${err.message}`;
    console.error('[ingest] ' + msg);
    await reply(room.id, root && root.event_id, msg, `<p><b>Ingest failed</b></p><pre>${esc(err.message)}</pre>`);
    process.exit(1);
  }

  const secs = Math.round((Date.now() - t0) / 1000);
  const link = `${DESK}/${r.skillPath}/`;
  const summary = `${r.rowCount} rows · ${r.cellCount} cells · ${r.totalFrames} frames · ${Math.floor(secs / 60)}m${secs % 60}s`
    + (r.rowErrors.length ? ` · ⚠ ${r.rowErrors.length} chapter error(s)` : '');
  console.log(`[ingest] DONE ${r.skillId}: ${summary}\n[ingest] ${link}`);
  await reply(room.id, root && root.event_id,
    `Ingested as ${r.skillId}: ${link}\n${summary}`,
    `<p>Ingested as <a href="${link}">${esc(r.skillId)} — ${esc(r.title || meta.title)}</a></p><p>${esc(summary)}</p>`
    + (r.rowErrors.length ? `<pre>${esc(r.rowErrors.slice(0, 5).join('\n'))}</pre>` : ''));
})().catch(err => {
  console.error('[ingest] ERROR:', err.message + (err.cause ? ` (${err.cause.code || err.cause.message})` : ''));
  process.exit(1);
});
