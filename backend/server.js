const express = require("express");
const cors = require("cors");
const crypto = require("node:crypto");
const mysql = require("mysql2/promise");

const PORT = Number(process.env.PORT || 3000);
const app = express();

const pool = mysql.createPool({
  host: process.env.DB_HOST || "127.0.0.1",
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || "root",
  password: process.env.DB_PASSWORD || "",
  database: process.env.DB_NAME || "cuzdanim_db",
  waitForConnections: true,
  connectionLimit: 10,
  enableKeepAlive: true,
  decimalNumbers: true,
  dateStrings: true,
});

app.disable("x-powered-by");
app.use(
  cors({
    origin:
      !process.env.CORS_ORIGIN || process.env.CORS_ORIGIN === "*"
        ? true
        : process.env.CORS_ORIGIN.split(",").map((item) => item.trim()),
  })
);
app.use(express.json({ limit: "64kb" }));

app.get("/", (_req, res) => {
  res.json({ name: "Cüzdanım API", status: "ok", version: "1.0.0" });
});

app.get("/health", async (_req, res) => {
  try {
    await pool.query("SELECT 1");
    res.json({ status: "ok" });
  } catch (_error) {
    res.status(503).json({ status: "unavailable", error: "Veritabanı bağlantısı kurulamadı." });
  }
});

app.post("/auth/register", async (req, res, next) => {
  try {
    const name = cleanText(req.body.name, 120);
    const email = cleanEmail(req.body.email);
    const password = String(req.body.password || "");
    if (name.length < 2 || !isEmail(email) || password.length < 6) {
      return res.status(400).json({ error: "Ad, geçerli e-posta ve en az 6 karakterli şifre zorunludur." });
    }
    const [existing] = await pool.query("SELECT id FROM users WHERE email = ? LIMIT 1", [email]);
    if (existing.length) return res.status(409).json({ error: "Bu e-posta zaten kayıtlı." });
    const [result] = await pool.query(
      "INSERT INTO users (name, email, password) VALUES (?, ?, ?)",
      [name, email, hashPassword(password)]
    );
    res.status(201).json({ user: { id: result.insertId, name, email } });
  } catch (error) {
    next(error);
  }
});

app.post("/auth/login", async (req, res, next) => {
  try {
    const email = cleanEmail(req.body.email);
    const password = String(req.body.password || "");
    if (!isEmail(email) || !password) return res.status(400).json({ error: "E-posta ve şifre zorunludur." });
    const [rows] = await pool.query(
      "SELECT id, name, email, password FROM users WHERE email = ? LIMIT 1",
      [email]
    );
    const user = rows[0];
    if (!user || !verifyPassword(password, user.password)) {
      return res.status(401).json({ error: "E-posta veya şifre hatalı." });
    }
    if (!String(user.password).startsWith("pbkdf2$")) {
      await pool.query("UPDATE users SET password = ? WHERE id = ?", [hashPassword(password), user.id]);
    }
    res.json({ user: { id: user.id, name: user.name, email: user.email } });
  } catch (error) {
    next(error);
  }
});

app.get("/transactions/:userId", async (req, res, next) => {
  try {
    const userId = positiveInt(req.params.userId);
    if (!userId) return res.status(400).json({ error: "Geçersiz kullanıcı." });
    const [items] = await pool.query(
      `SELECT id, user_id, amount, type, category, description, date
       FROM transactions WHERE user_id = ? ORDER BY date DESC, id DESC`,
      [userId]
    );
    res.json({ items });
  } catch (error) {
    next(error);
  }
});

app.post("/transactions", async (req, res, next) => {
  try {
    const input = validateTransaction(req.body);
    if (input.error) return res.status(400).json({ error: input.error });
    const [result] = await pool.query(
      `INSERT INTO transactions (user_id, amount, type, category, description, date)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [input.userId, input.amount, input.type, input.category, input.description, input.date]
    );
    const [rows] = await pool.query(
      "SELECT id, user_id, amount, type, category, description, date FROM transactions WHERE id = ?",
      [result.insertId]
    );
    res.status(201).json({ transaction: rows[0] });
  } catch (error) {
    next(error);
  }
});

app.put("/transactions/:id", async (req, res, next) => {
  try {
    const id = positiveInt(req.params.id);
    const input = validateTransaction(req.body);
    if (!id || input.error) return res.status(400).json({ error: input.error || "Geçersiz işlem." });
    const [result] = await pool.query(
      `UPDATE transactions SET amount = ?, type = ?, category = ?, description = ?, date = ?
       WHERE id = ? AND user_id = ?`,
      [input.amount, input.type, input.category, input.description, input.date, id, input.userId]
    );
    if (!result.affectedRows) return res.status(404).json({ error: "İşlem bulunamadı." });
    const [rows] = await pool.query(
      "SELECT id, user_id, amount, type, category, description, date FROM transactions WHERE id = ?",
      [id]
    );
    res.json({ transaction: rows[0] });
  } catch (error) {
    next(error);
  }
});

app.delete("/transactions/:id", async (req, res, next) => {
  try {
    const id = positiveInt(req.params.id);
    const userId = positiveInt(req.query.userId);
    if (!id || !userId) return res.status(400).json({ error: "Geçersiz işlem." });
    const [result] = await pool.query("DELETE FROM transactions WHERE id = ? AND user_id = ?", [id, userId]);
    if (!result.affectedRows) return res.status(404).json({ error: "İşlem bulunamadı." });
    res.status(204).end();
  } catch (error) {
    next(error);
  }
});

app.get("/budgets/:userId", async (req, res, next) => {
  try {
    const userId = positiveInt(req.params.userId);
    if (!userId) return res.status(400).json({ error: "Geçersiz kullanıcı." });
    const [items] = await pool.query(
      "SELECT id, user_id, category, amount, month FROM budgets WHERE user_id = ? ORDER BY month DESC, category",
      [userId]
    );
    res.json({ items });
  } catch (error) {
    next(error);
  }
});

app.post("/budgets", async (req, res, next) => {
  try {
    const input = validateBudget(req.body);
    if (input.error) return res.status(400).json({ error: input.error });
    await pool.query(
      `INSERT INTO budgets (user_id, category, amount, month) VALUES (?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE amount = VALUES(amount), id = LAST_INSERT_ID(id)`,
      [input.userId, input.category, input.amount, input.month]
    );
    const [rows] = await pool.query(
      "SELECT id, user_id, category, amount, month FROM budgets WHERE user_id = ? AND category = ? AND month = ?",
      [input.userId, input.category, input.month]
    );
    res.status(201).json({ budget: rows[0] });
  } catch (error) {
    next(error);
  }
});

app.put("/budgets/:id", async (req, res, next) => {
  try {
    const id = positiveInt(req.params.id);
    const input = validateBudget(req.body);
    if (!id || input.error) return res.status(400).json({ error: input.error || "Geçersiz bütçe." });
    const [result] = await pool.query(
      "UPDATE budgets SET category = ?, amount = ?, month = ? WHERE id = ? AND user_id = ?",
      [input.category, input.amount, input.month, id, input.userId]
    );
    if (!result.affectedRows) return res.status(404).json({ error: "Bütçe bulunamadı." });
    const [rows] = await pool.query("SELECT id, user_id, category, amount, month FROM budgets WHERE id = ?", [id]);
    res.json({ budget: rows[0] });
  } catch (error) {
    next(error);
  }
});

app.delete("/budgets/:id", async (req, res, next) => {
  try {
    const id = positiveInt(req.params.id);
    const userId = positiveInt(req.query.userId);
    if (!id || !userId) return res.status(400).json({ error: "Geçersiz bütçe." });
    const [result] = await pool.query("DELETE FROM budgets WHERE id = ? AND user_id = ?", [id, userId]);
    if (!result.affectedRows) return res.status(404).json({ error: "Bütçe bulunamadı." });
    res.status(204).end();
  } catch (error) {
    next(error);
  }
});

app.use((_req, res) => res.status(404).json({ error: "İstenen adres bulunamadı." }));

app.use((error, _req, res, _next) => {
  console.error(error);
  if (error?.code === "ER_DUP_ENTRY") return res.status(409).json({ error: "Bu kayıt zaten mevcut." });
  res.status(500).json({ error: "Sunucuda beklenmeyen bir hata oluştu." });
});

function validateTransaction(body) {
  const userId = positiveInt(body.userId ?? body.user_id);
  const amount = Number(body.amount);
  const type = String(body.type || "").toLowerCase();
  const category = cleanText(body.category, 80);
  const description = cleanText(body.description, 255);
  const date = validDate(body.date);
  if (!userId || !Number.isFinite(amount) || amount <= 0 || !["income", "expense"].includes(type) || !category || !description || !date) {
    return { error: "Kullanıcı, pozitif tutar, tür, kategori, açıklama ve geçerli tarih zorunludur." };
  }
  return { userId, amount, type, category, description, date };
}

function validateBudget(body) {
  const userId = positiveInt(body.userId ?? body.user_id);
  const amount = Number(body.amount);
  const category = cleanText(body.category, 80);
  const month = validDate(body.month);
  if (!userId || !Number.isFinite(amount) || amount <= 0 || !category || !month) {
    return { error: "Kullanıcı, kategori, pozitif tutar ve geçerli ay zorunludur." };
  }
  return { userId, amount, category, month: `${month.slice(0, 7)}-01` };
}

function cleanText(value, maxLength) {
  return String(value || "").trim().replace(/\s+/g, " ").slice(0, maxLength);
}

function cleanEmail(value) {
  return String(value || "").trim().toLowerCase().slice(0, 160);
}

function isEmail(value) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
}

function positiveInt(value) {
  const number = Number(value);
  return Number.isSafeInteger(number) && number > 0 ? number : 0;
}

function validDate(value) {
  const text = String(value || "").slice(0, 10);
  return /^\d{4}-\d{2}-\d{2}$/.test(text) && !Number.isNaN(Date.parse(`${text}T00:00:00Z`)) ? text : "";
}

function hashPassword(password) {
  const salt = crypto.randomBytes(16).toString("hex");
  const hash = crypto.pbkdf2Sync(password, salt, 120000, 32, "sha256").toString("hex");
  return `pbkdf2$${salt}$${hash}`;
}

function verifyPassword(password, stored) {
  const value = String(stored || "");
  if (!value.startsWith("pbkdf2$")) {
    const givenBuffer = Buffer.from(password);
    const storedBuffer = Buffer.from(value);
    return givenBuffer.length === storedBuffer.length && crypto.timingSafeEqual(givenBuffer, storedBuffer);
  }
  const [, salt, expected] = value.split("$");
  if (!salt || !expected) return false;
  const actual = crypto.pbkdf2Sync(password, salt, 120000, 32, "sha256").toString("hex");
  return actual.length === expected.length && crypto.timingSafeEqual(Buffer.from(actual), Buffer.from(expected));
}

let server;
function start() {
  if (server) return server;
  server = app.listen(PORT, () => console.log(`Cüzdanım API http://127.0.0.1:${PORT} adresinde hazır.`));
  return server;
}

async function shutdown() {
  if (server) await new Promise((resolve) => server.close(resolve));
  await pool.end();
}

if (require.main === module) start();

process.once("SIGINT", async () => { await shutdown(); process.exit(0); });
process.once("SIGTERM", async () => { await shutdown(); process.exit(0); });

module.exports = { app, pool, start, shutdown };
