const express = require("express");
const http = require("http");
const mongoose = require("mongoose");
const cors = require("cors");
const path = require("path");
const dotenv = require("dotenv");
const bcrypt = require("bcryptjs");
const fs = require("fs");
const multer = require("multer");
const os = require("os");

dotenv.config();
// .env.local peut surcharger .env (comme sur beaucoup de stacks) — utile pour déboguer le 503 Mongo.
dotenv.config({ path: path.join(__dirname, ".env.local"), override: true });

const app = express();
app.use(
  cors({
    origin: true,
    methods: ["GET", "HEAD", "PUT", "PATCH", "POST", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization", "Accept", "ngrok-skip-browser-warning"],
  }),
);
app.use(express.json());

// Uploads (pieces jointes chat)
const UPLOADS_DIR = path.join(__dirname, "uploads");
if (!fs.existsSync(UPLOADS_DIR)) {
  fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}
app.use("/uploads", express.static(UPLOADS_DIR));

function safeFilename(name) {
  return String(name || "file")
    .replace(/[^\w.\-]+/g, "_")
    .replace(/_+/g, "_")
    .slice(0, 80);
}

const upload = multer({
  storage: multer.diskStorage({
    destination: (_req, _file, cb) => cb(null, UPLOADS_DIR),
    filename: (_req, file, cb) => {
      const ext = path.extname(file.originalname || "");
      const base = safeFilename(path.basename(file.originalname || "file", ext));
      cb(null, `${Date.now()}_${base}${ext}`);
    },
  }),
  limits: { fileSize: 15 * 1024 * 1024 }, // 15MB
});

// Même logique que flutter_backend : URI Atlas ou locale (priorité MONGO_URI puis MONGODB_URI)
const MONGO_URI =
  process.env.MONGO_URI ||
  process.env.MONGODB_URI ||
  "";

/** Collection Atlas des alertes (GET/PATCH /api/notifications*). Défaut : `alerts` (pluriel, nom Atlas courant). */
const NOTIFICATIONS_ALERT_COLLECTION = (() => {
  const raw = String(
    process.env.NOTIFICATIONS_ALERT_COLLECTION ||
      process.env.MONGO_ALERT_COLLECTION ||
      "alerts"
  ).trim();
  return raw || "alerts";
})();

/** Collection problèmes IA / voirie (détail chantier mobile). */
const PROBLEMES_VOIRIE_COLLECTION =
  String(process.env.PROBLEMES_VOIRIE_COLLECTION || "problemes_de_voirie").trim() || "problemes_de_voirie";

/** Masque le mot de passe dans l’URI pour les logs (évite de fuiter les identifiants). */
function maskMongoUri(uri) {
  if (!uri) return "(vide)";
  return uri.replace(/:([^:@/]{1,})@/, ":****@");
}

if (process.env.DEBUG_MONGO === "1") {
  console.log("[env] MONGO_URI =", MONGO_URI);
} else {
  console.log("[env] MONGO_URI (masque) =", maskMongoUri(MONGO_URI), "(DEBUG_MONGO=1 pour URI complet)");
}

let isMongoConnected = false;

const IntervenantSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    nom: { type: String, required: true },
    prenom: { type: String, required: true },
    equipe: { type: String, required: true },
    responsable: { type: String, default: "" },
    phone: { type: String, default: "" },
    zone: { type: String, default: "" },
    speciality: { type: String, default: "" },
    membersCount: { type: Number, default: 1 },
    completedChantiers: { type: Number, default: 0 },
    currentChantiers: { type: Number, default: 0 },
    urgentChantiers: { type: Number, default: 0 },
    avgInterventionTime: { type: String, default: "2h" },
    rating: { type: Number, default: 4.5 },
    profileImage: { type: String, default: "" },
    notificationsEnabled: { type: Boolean, default: true },
    darkModeEnabled: { type: Boolean, default: false },
    preferredLanguage: { type: String, default: "fr" },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    passwordHash: { type: String, required: true },
    createdAt: { type: Date, default: Date.now },
  },
  { collection: "intervenants" }
);

const Intervenant = mongoose.model("Intervenant", IntervenantSchema);
const ChatIntervenantSchema = new mongoose.Schema(
  {
    intervenantId: { type: String, required: true, trim: true },
    intervenantName: { type: String, required: true, trim: true },
    senderRole: { type: String, enum: ["intervenant", "admin"], required: true },
    /** Alias API / imports Mongo (même sens que senderRole). */
    sender_type: { type: String, trim: true },
    from_admin: { type: Boolean },
    author_label: { type: String, trim: true },
    author_key: { type: String, trim: true },
    message: { type: String, trim: true },
    text: { type: String, required: true, trim: true },
    attachments: {
      type: [
        {
          kind: { type: String, enum: ["image", "document", "other"], required: true },
          name: { type: String, required: true },
          mime: { type: String, required: true },
          size: { type: Number, required: true },
          url: { type: String, required: true },
        },
      ],
      default: [],
    },
    createdAt: { type: Date, default: Date.now },
  },
  { collection: "chat_intervenant" }
);

ChatIntervenantSchema.index({ intervenantId: 1, createdAt: 1 });
const ChatIntervenant = mongoose.model("ChatIntervenant", ChatIntervenantSchema);

/** Ex. « Équipe 1 » / « equipe_1 » → `sh_eq1team001` (convention Atlas / messagerie admin). */
function deriveMessagingIdsFromEquipe(equipe) {
  const s = String(equipe || "").trim();
  const mm = s.match(/(\d+)/);
  if (!mm) return [];
  const n = mm[1];
  return [`sh_eq${n}team001`];
}

/**
 * Tous les identifiants de fil de discussion possibles (email compte + id terrain type `sh_eq…`).
 * Les messages admin sont souvent enregistrés sous `sh_eq1team001` alors que l’app mobile envoie l’email.
 */
async function chatParticipantIdAlternatives(rawId) {
  const id = String(rawId || "").trim();
  if (!id) return [];
  const set = new Set();
  set.add(id);
  if (id.includes("@")) set.add(id.toLowerCase());
  const looksEmail = id.includes("@");
  if (looksEmail) {
    try {
      const u = await Intervenant.findOne({ email: id.toLowerCase() }).select({ equipe: 1 }).lean();
      for (const x of deriveMessagingIdsFromEquipe(u?.equipe)) set.add(x);
    } catch (_) {}
  }
  return [...set].filter(Boolean);
}

/** Si l’app envoie l’email, enregistrer sous l’id messagerie `sh_eq…` quand l’équipe le permet (un seul fil avec l’admin). */
async function normalizeChatIntervenantIdForWrite(rawId) {
  const id = String(rawId || "").trim();
  if (!id) return id;
  if (!id.includes("@")) return id;
  try {
    const u = await Intervenant.findOne({ email: id.toLowerCase() }).select({ equipe: 1 }).lean();
    const derived = deriveMessagingIdsFromEquipe(u?.equipe || "");
    if (derived[0]) return derived[0];
  } catch (_) {}
  return id;
}

/**
 * Collection `notification_intervenant` — utilisée pour le seed à l’inscription.
 * L’écran Notifications lit la collection alertes (`alerts` par défaut, voir NOTIFICATIONS_ALERT_COLLECTION).
 */
const NotificationSchema = new mongoose.Schema(
  {},
  { collection: "notification_intervenant", strict: false, timestamps: false }
);

NotificationSchema.index({ userId: 1, createdAt: -1 });
NotificationSchema.index({ email: 1, createdAt: -1 });
const Notification = mongoose.model("Notification", NotificationSchema);

/** Collection Atlas (nom configurable via NOTIFICATIONS_ALERT_COLLECTION) — listes / compteurs / lu. */
const AlertSchema = new mongoose.Schema(
  {},
  { collection: NOTIFICATIONS_ALERT_COLLECTION, strict: false, timestamps: false }
);
AlertSchema.index({ userId: 1, createdAt: -1 });
AlertSchema.index({ email: 1, createdAt: -1 });
const Alert = mongoose.model("Alert", AlertSchema);

/** Atlas nomme souvent la collection `alert` (singulier) ou `alerts` (pluriel). */
function alternateAlertCollectionName(name) {
  const n = String(name || "").trim().toLowerCase();
  if (n === "alerts") return "alert";
  if (n === "alert") return "alerts";
  return null;
}

let _resolvedAlertsCollection = null;

/**
 * Collection physique où se trouvent les documents (auto si la collection .env est vide mais l’autre non).
 */
async function getResolvedAlertsCollectionName() {
  if (_resolvedAlertsCollection) return _resolvedAlertsCollection;
  if (!mongoose.connection.readyState || !mongoose.connection.db) {
    _resolvedAlertsCollection = NOTIFICATIONS_ALERT_COLLECTION;
    return _resolvedAlertsCollection;
  }
  const db = mongoose.connection.db;
  const primary = NOTIFICATIONS_ALERT_COLLECTION;
  const alt = alternateAlertCollectionName(primary);
  let n1 = 0;
  try {
    n1 = await db.collection(primary).estimatedDocumentCount();
  } catch (_) {
    n1 = 0;
  }
  if (n1 > 0) {
    _resolvedAlertsCollection = primary;
    console.log(
      `[api] Alertes : collection « ${primary} » — ${n1} document(s) (base « ${db.databaseName} »).`
    );
    return primary;
  }
  if (alt) {
    let n2 = 0;
    try {
      n2 = await db.collection(alt).estimatedDocumentCount();
    } catch (_) {
      n2 = 0;
    }
    if (n2 > 0) {
      _resolvedAlertsCollection = alt;
      console.warn(
        `[api] « ${primary} » est vide — utilisation de « ${alt} » (${n2} document(s)). ` +
          `Fix .env : NOTIFICATIONS_ALERT_COLLECTION=${alt}`
      );
      return alt;
    }
  }
  _resolvedAlertsCollection = primary;
  console.warn(
    `[api] Aucune alerte dans « ${primary} »${alt ? ` ni « ${alt} »` : ""} (base « ${db.databaseName} »). Vérifiez le nom exact dans Atlas.`
  );
  return primary;
}

async function alertsNativeCollection() {
  return mongoose.connection.db.collection(await getResolvedAlertsCollectionName());
}

/** Affectations chantier (supervision terrain ↔ admin). */
const ChantierAssignmentSchema = new mongoose.Schema(
  {
    problem_id: { type: String, default: "" },
    team: { type: String, default: "" },
    team_key: { type: String, default: "" },
    title: { type: String, required: true },
    type: { type: String, default: "" },
    description: { type: String, default: "" },
    address: { type: String, default: "" },
    status: { type: String, default: "assigné" },
    estimated_cost: { type: String, default: "" },
    risk_score: { type: Number, default: 0 },
    severity: { type: String, default: "" },
    confidence: { type: Number, default: 0 },
    detected_at: { type: String, default: "" },
    priority: { type: String, default: "normale" },
    lat: { type: Number },
    lng: { type: Number },
  },
  {
    collection: "chantier_assignments",
    timestamps: { createdAt: "created_at", updatedAt: "updated_at" },
  }
);

ChantierAssignmentSchema.index({ team: 1, updated_at: -1 });
const ChantierAssignment = mongoose.model("ChantierAssignment", ChantierAssignmentSchema);

/** Problèmes de voirie (schéma Atlas souple). */
const ProblemeVoirieSchema = new mongoose.Schema(
  {},
  { collection: PROBLEMES_VOIRIE_COLLECTION, strict: false, timestamps: false }
);
ProblemeVoirieSchema.index({ assigned_team: 1, updated_at: -1 });
const ProblemeVoirie = mongoose.model("ProblemeVoirie", ProblemeVoirieSchema);

function assignmentDocToApiItem(doc) {
  const o = doc && typeof doc.toObject === "function" ? doc.toObject() : doc;
  const id = o._id ? String(o._id) : "";
  const updated = o.updated_at || o.updatedAt;
  let updatedAtStr = "";
  if (updated instanceof Date) updatedAtStr = updated.toISOString();
  else if (updated) updatedAtStr = String(updated);
  return {
    id,
    problem_id: String(o.problem_id || "").trim(),
    team: String(o.team || "").trim(),
    title: String(o.title || "Intervention").trim(),
    type: String(o.type || "").trim(),
    description: String(o.description || "").trim(),
    address: String(o.address || "").trim(),
    status: String(o.status || "assigné").trim(),
    estimated_cost: String(o.estimated_cost || "").trim(),
    risk_score: typeof o.risk_score === "number" ? o.risk_score : Number(o.risk_score) || 0,
    severity: String(o.severity || "").trim(),
    confidence: typeof o.confidence === "number" ? o.confidence : Number(o.confidence) || 0,
    detected_at: String(o.detected_at || "").trim(),
    priority: String(o.priority || "").trim(),
    lat: o.lat,
    lng: o.lng,
    updated_at: updatedAtStr,
  };
}

/** Filtre équipe (query Flutter : team_label, team_key). */
function assignmentMongoFilter(teamLabel, teamKey) {
  const t = String(teamLabel || "").trim();
  const k = String(teamKey || "").trim();
  if (!t && !k) return {};
  const or = [];
  if (t) {
    const esc = t.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    or.push({ team: new RegExp(esc, "i") });
    const mt = t.match(/(\d+)/);
    if (mt && mt[1]) {
      or.push({ team: new RegExp(`[eé]quipe[_\\s]?${mt[1]}`, "i") });
    }
  }
  if (k) {
    or.push({ team_key: k });
    const num = k.replace(/^equipe_?/i, "");
    if (num) {
      or.push({ team: new RegExp(`[eé]quipe[_\\s]?${num}`, "i") });
    }
  }
  return or.length ? { $or: or } : {};
}

/** Filtre équipe pour `problemes_de_voirie` (assigned_team, team, equipe). */
function problemesVoirieMongoFilter(teamLabel, teamKey) {
  const t = String(teamLabel || "").trim();
  const k = String(teamKey || "").trim();
  if (!t && !k) return {};
  const or = [];
  if (t) {
    const esc = t.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    or.push({ team: new RegExp(esc, "i") });
    or.push({ equipe: new RegExp(esc, "i") });
    or.push({ assigned_team: new RegExp(esc, "i") });
    const mt = t.match(/(\d+)/);
    if (mt && mt[1]) {
      const num = mt[1];
      or.push({ team: new RegExp(`[eé]quipe[_\\s]?${num}`, "i") });
      or.push({ equipe: new RegExp(`[eé]quipe[_\\s]?${num}`, "i") });
      or.push({ assigned_team: new RegExp(`^equipe[_]?${num}$`, "i") });
      or.push({ assigned_team: new RegExp(`[eé]quipe[_\\s-]?${num}`, "i") });
    }
  }
  if (k) {
    or.push({ assigned_team: k });
    const num = k.replace(/^equipe_?/i, "");
    if (num) {
      or.push({ assigned_team: new RegExp(`^equipe[_]?${num}$`, "i") });
      or.push({ assigned_team: new RegExp(`[eé]quipe[_\\s-]?${num}`, "i") });
      or.push({ team: new RegExp(`[eé]quipe[_\\s]?${num}`, "i") });
      or.push({ equipe: new RegExp(`[eé]quipe[_\\s]?${num}`, "i") });
    }
  }
  return or.length ? { $or: or } : {};
}

/** Limite liste problèmes voirie (tous les docs équipe, sans plafond trop bas). */
function problemesVoirieListLimit(req) {
  const limitRaw = Number.parseInt(String(req.query.limit ?? "2000"), 10);
  return Number.isFinite(limitRaw) ? Math.min(Math.max(limitRaw, 1), 5000) : 2000;
}

function problemeVoirieDateToIso(v) {
  if (!v) return "";
  if (v instanceof Date) return v.toISOString();
  return String(v);
}

function problemeVoirieToApi(raw) {
  const o = raw && typeof raw.toObject === "function" ? raw.toObject() : raw;
  const locRaw = o.location && typeof o.location === "object" ? o.location : {};
  const mergedAddr = problemeVoirieMergedAddress(o);
  const { lat, lng } = problemeVoirieExtractCoords(o);
  const loc =
    Object.keys(locRaw).length > 0
      ? { ...locRaw, ...(mergedAddr ? { address: mergedAddr } : {}) }
      : mergedAddr
        ? { type: "Point", address: mergedAddr }
        : {};
  const confRaw = o.confidence;
  const conf = typeof confRaw === "number" ? confRaw : Number.parseFloat(confRaw) || 0;
  const rs = o.risk_score;
  const risk = typeof rs === "number" ? rs : Number.parseFloat(rs) || 0;
  const td = o.total_defects;
  const totalDef =
    typeof td === "number" && Number.isFinite(td) ? Math.trunc(td) : Number.parseInt(String(td || 0), 10) || 0;
  const st = String(o.status || o.statut || "").trim();
  return {
    id: String(o._id || ""),
    problem_type: String(o.problem_type || "").trim(),
    total_defects: totalDef,
    location: loc,
    address: mergedAddr,
    lat: Number.isFinite(lat) ? lat : undefined,
    lng: Number.isFinite(lng) ? lng : undefined,
    risk_score: risk,
    severity: String(o.severity || "").trim(),
    confidence: conf,
    ai_model: String(o.ai_model || "").trim(),
    date_detection: problemeVoirieDateToIso(o.date_detection),
    description: String(o.description || "").trim(),
    description_fr: String(o.description_fr || "").trim(),
    description_ar: String(o.description_ar || "").trim(),
    status: st,
    statut: st,
    updated_at: problemeVoirieDateToIso(o.updated_at),
    assigned_team: String(o.assigned_team || "").trim(),
    equipe: String(o.equipe || "").trim(),
    team: String(o.team || "").trim(),
    cout_estime: String(o.cout_estime ?? "").trim(),
    photos: Array.isArray(o.photos) ? o.photos : [],
  };
}

function normalizeAssignmentStatusInput(raw) {
  const s = String(raw || "")
    .trim()
    .toLowerCase()
    .replace(/\s+/g, "_");
  const map = {
    assigné: "assigné",
    assignee: "assigné",
    assigned: "assigné",
    pending: "assigné",
    nouveau: "assigné",
    en_cours: "en_cours",
    in_progress: "en_cours",
    processing: "en_cours",
    en_traitement: "en_cours",
    en_pause: "en_pause",
    pause: "en_pause",
    paused: "en_pause",
    terminé: "terminé",
    termine: "terminé",
    completed: "terminé",
    done: "terminé",
    closed: "terminé",
    cloture: "terminé",
    clôturé: "terminé",
  };
  return map[s] || null;
}

async function seedDemoChantierAssignmentsIfEmpty() {
  if (!isMongoConnected) return;
  try {
    const n = await ChantierAssignment.countDocuments();
    if (n > 0) return;
    const now = Date.now();
    await ChantierAssignment.insertMany([
      {
        problem_id: "prob_demo_1",
        team: "Équipe 1",
        team_key: "equipe_1",
        title: "Nid de poule — Avenue Habib Bourguiba",
        type: "nid_de_poule",
        description: "Déformation notable, danger pour deux-roues.",
        address: "Ave Habib Bourguiba, Sfax",
        status: "assigné",
        estimated_cost: "1200 TND",
        risk_score: 72,
        severity: "élevée",
        confidence: 88,
        detected_at: new Date(now - 86400000).toISOString(),
        priority: "haute",
        lat: 34.7406,
        lng: 10.7603,
      },
      {
        problem_id: "prob_demo_2",
        team: "Équipe 1",
        team_key: "equipe_1",
        title: "Dégradation de revêtement",
        type: "degradation_route",
        description: "Ornières et affaissement localisé après pluie.",
        address: "Route de l'Aéroport, Sfax",
        status: "en_cours",
        estimated_cost: "4500 TND",
        risk_score: 55,
        severity: "moyenne",
        confidence: 76,
        detected_at: new Date(now - 172800000).toISOString(),
        priority: "normale",
        lat: 34.7179,
        lng: 10.6917,
      },
      {
        problem_id: "prob_demo_3",
        team: "Équipe 1",
        team_key: "equipe_1",
        title: "Signalisation effacée",
        type: "signalisation",
        description: "Marquage au sol peu visible sur carrefour.",
        address: "Bd de la Liberté, Sfax",
        status: "terminé",
        estimated_cost: "800 TND",
        risk_score: 30,
        severity: "faible",
        confidence: 92,
        detected_at: new Date(now - 604800000).toISOString(),
        priority: "basse",
        lat: 34.732,
        lng: 10.748,
      },
    ]);
    console.log("[seed] chantier_assignments : 3 exemples insérés (équipe 1).");
  } catch (e) {
    console.error("[seed] chantier_assignments :", e.message || e);
  }
}

/** Filtre Mongo : notification liée à l’email / userId intervenant. */
function notificationUserQuery(uid) {
  const u = String(uid || "").trim().toLowerCase();
  const or = [
    { userId: u },
    { email: u },
    { intervenant_email: u },
    { intervenantEmail: u },
    { intervenantId: u },
  ];
  if (/^[a-fA-F0-9]{24}$/.test(u)) {
    try {
      or.push({ intervenantId: new mongoose.Types.ObjectId(u) });
    } catch (_) {
      /* ignore */
    }
  }
  return { $or: or };
}

/** Plusieurs clés (email + interv_001, …) pour les notifications « problème ». */
function notificationMultiUserQuery(rawIds) {
  const seen = new Set();
  const ids = [];
  for (const raw of rawIds) {
    const x = String(raw || "").trim();
    if (!x) continue;
    const k = x.toLowerCase();
    if (seen.has(k)) continue;
    seen.add(k);
    ids.push(x);
  }
  if (!ids.length) return null;
  if (ids.length === 1) return notificationUserQuery(ids[0]);
  return { $or: ids.map((id) => notificationUserQuery(id)) };
}

function notificationMultiUnreadQuery(rawIds) {
  const base = notificationMultiUserQuery(rawIds);
  if (!base) return null;
  return {
    $and: [
      base,
      { isRead: { $ne: true } },
      { lu: { $ne: true } },
      { read: { $ne: true } },
    ],
  };
}

/** Non lue pour une alerte (les docs Atlas n’ont souvent ni userId ni isRead). */
function alertUnreadOnlyFilter() {
  return {
    $and: [
      { isRead: { $ne: true } },
      { lu: { $ne: true } },
      { read: { $ne: true } },
    ],
  };
}

/** Lat/lng depuis un sous-objet (position, location, GeoJSON Point, etc.). */
function parseCoordsFromMap(obj) {
  if (!obj || typeof obj !== "object") return null;
  let lat = obj.latitude ?? obj.lat ?? obj.Latitude;
  let lng = obj.longitude ?? obj.lng ?? obj.lon ?? obj.Longitude;
  if (typeof lat === "string") lat = Number.parseFloat(lat);
  if (typeof lng === "string") lng = Number.parseFloat(lng);
  if (
    typeof lat === "number" &&
    typeof lng === "number" &&
    Number.isFinite(lat) &&
    Number.isFinite(lng)
  ) {
    return { latitude: lat, longitude: lng };
  }
  const coords = obj.coordinates;
  if (Array.isArray(coords) && coords.length >= 2) {
    const lon = Number(coords[0]);
    const la = Number(coords[1]);
    if (Number.isFinite(lon) && Number.isFinite(la)) {
      return { latitude: la, longitude: lon };
    }
  }
  return null;
}

/** Adresse texte : `location.address`, champs racine, ou libellé synthétique lat/lon/précision. */
function problemeVoirieMergedAddress(o) {
  if (!o || typeof o !== "object") return "";
  const loc = o.location && typeof o.location === "object" ? o.location : {};
  const fromLoc = String(loc.address || "").trim();
  if (fromLoc) return fromLoc;
  const fromRoot = String(o.address || o.adresse || o.Adresse || o.street || o.rue || o.localisation || "").trim();
  if (fromRoot) return fromRoot;
  const { lat, lng } = problemeVoirieExtractCoords(o);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return "";
  const accRaw = loc.accuracy ?? o.accuracy;
  const acc = typeof accRaw === "number" ? accRaw : Number.parseFloat(accRaw);
  const accStr = Number.isFinite(acc) ? `, accuracy: ${acc}m` : "";
  return `lat: ${lat}, lon: ${lng}${accStr}`;
}

/** Lat/lng : GeoJSON Point, objets `position` / `location` avec lat/lng, ou champs racine. */
function problemeVoirieExtractCoords(o) {
  if (!o || typeof o !== "object") return {};
  const loc = o.location && typeof o.location === "object" ? o.location : null;
  if (loc && Array.isArray(loc.coordinates) && loc.coordinates.length >= 2) {
    const lng = Number(loc.coordinates[0]);
    const lat = Number(loc.coordinates[1]);
    if (Number.isFinite(lat) && Number.isFinite(lng)) return { lat, lng };
  }
  const nested = parseCoordsFromMap(loc) || parseCoordsFromMap(o.position);
  if (nested && Number.isFinite(nested.latitude) && Number.isFinite(nested.longitude)) {
    return { lat: nested.latitude, lng: nested.longitude };
  }
  let lat = o.lat ?? o.latitude ?? o.Latitude;
  let lng = o.lng ?? o.longitude ?? o.lon ?? o.Longitude;
  if (typeof lat === "string") lat = Number.parseFloat(lat);
  if (typeof lng === "string") lng = Number.parseFloat(lng);
  if (Number.isFinite(lat) && Number.isFinite(lng)) return { lat, lng };
  return {};
}

/** Extrait latitude / longitude depuis le document Mongo (position, location Atlas `alert`, racine). */
function notificationParsePosition(doc) {
  if (!doc || typeof doc !== "object") return null;
  const nested = parseCoordsFromMap(doc.position) || parseCoordsFromMap(doc.location);
  if (nested) return nested;
  let rootLat = doc.latitude ?? doc.lat ?? doc.Latitude;
  let rootLng = doc.longitude ?? doc.lng ?? doc.lon ?? doc.Longitude;
  if (typeof rootLat === "string") rootLat = Number.parseFloat(rootLat);
  if (typeof rootLng === "string") rootLng = Number.parseFloat(rootLng);
  if (
    typeof rootLat === "number" &&
    typeof rootLng === "number" &&
    Number.isFinite(rootLat) &&
    Number.isFinite(rootLng)
  ) {
    return { latitude: rootLat, longitude: rootLng };
  }
  return null;
}

/** Chaîne stable pour chips / filtres (ex. « Temperature moderee » → temperature_moderee). */
function slugifyAlertLabel(text) {
  const t = String(text || "")
    .trim()
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "");
  if (!t) return "";
  return t.replace(/[^a-z0-9]+/g, "_").replace(/_+/g, "_").replace(/^_|_$/g, "");
}

/** priority Atlas (low | medium | high) → gravité FR attendue par l’app. */
function priorityToGravite(priorityRaw) {
  const p = String(priorityRaw || "")
    .trim()
    .toLowerCase();
  if (p === "low" || p === "basse" || p === "faible") return "faible";
  if (p === "medium" || p === "moderate" || p === "moderee" || p === "modérée" || p === "moyenne" || p === "normal")
    return "moyenne";
  if (p === "high" || p === "haute" || p === "critical" || p === "grave" || p === "severe" || p === "sévère")
    return "grave";
  return "";
}

/** Non lue si ni isRead ni lu ni read ne sont vrais. */
function notificationUnreadQuery(uid) {
  return {
    $and: [
      notificationUserQuery(uid),
      { isRead: { $ne: true } },
      { lu: { $ne: true } },
      { read: { $ne: true } },
    ],
  };
}

function notificationToApi(n) {
  const uid =
    n.userId ||
    n.email ||
    n.intervenant_email ||
    n.intervenantEmail ||
    n.intervenantId ||
    "";
  const alertType = String(n.alert_type || "").trim();
  const sourceRaw = String(n.source || "").trim();
  const sourceLower = sourceRaw.toLowerCase().replace(/-/g, "_");

  const title =
    String(n.title || n.titre || "").trim() ||
    alertType ||
    (sourceRaw ? sourceRaw.replace(/_/g, " ") : "") ||
    "";

  let message = String(
    n.message || n.contenu || n.texte || n.description || n.body || ""
  ).trim();
  const recommendation = String(n.recommendation || "").trim();
  if (recommendation && message && !message.includes(recommendation.slice(0, Math.min(48, recommendation.length)))) {
    message = `${message}\n\n${recommendation}`;
  } else if (recommendation && !message) {
    message = recommendation;
  }

  const typeNotifField = String(n.typeNotification || n.type_notif || sourceLower || "")
    .trim()
    .toLowerCase();
  const typeLegacy = String(n.type || n.categorie || n.category || sourceLower || "")
    .trim()
    .toLowerCase();
  const typeNotification = typeNotifField || typeLegacy || "system_update";
  const type = typeLegacy || typeNotifField || "system_update";

  let typeProbleme = String(n.typeProbleme || n.type_probleme || "")
    .trim()
    .toLowerCase();
  if (!typeProbleme && alertType) typeProbleme = slugifyAlertLabel(alertType);
  if (!typeProbleme && sourceLower) typeProbleme = sourceLower;

  let gravite = String(n.gravite || n.gravity || n.severity || "")
    .trim()
    .toLowerCase();
  if (!gravite) gravite = priorityToGravite(n.priority);

  const status = String(n.status || n.statut || "")
    .trim()
    .toLowerCase();
  const isRead = n.isRead === true || n.lu === true || n.read === true;
  const relatedId = String(
    n.relatedId || n.reference_id || n.signalement_id || n.related_id || ""
  ).trim();
  const createdAt =
    n.createdAt ||
    n.date_creation ||
    n.created_at ||
    n.detected_at ||
    n.timestamp ||
    n.updatedAt ||
    n.date ||
    new Date(0);
  const position = notificationParsePosition(n);
  return {
    _id: String(n._id),
    id: String(n._id),
    userId: String(uid).toLowerCase(),
    title: title || "(Sans titre)",
    /** Alias MongoDB / clients FR (même contenu que title) */
    titre: title || "(Sans titre)",
    /** Champs bruts utiles au debug / clients (collection `alert`). */
    source: sourceRaw || undefined,
    alert_type: alertType || undefined,
    priority: n.priority != null ? String(n.priority) : undefined,
    temperature_c:
      typeof n.temperature_c === "number" && Number.isFinite(n.temperature_c)
        ? n.temperature_c
        : Number.isFinite(Number.parseFloat(n.temperature_c))
          ? Number.parseFloat(n.temperature_c)
          : undefined,
    message,
    /** @deprecated préférer typeNotification — conservé pour les anciennes apps */
    type,
    typeNotification,
    typeProbleme,
    gravite,
    status,
    position,
    isRead,
    relatedId,
    createdAt,
  };
}

if (!MONGO_URI) {
  console.error(
    "Missing MONGO_URI or MONGODB_URI in backend/.env (ex. mongodb+srv://... comme flutter_backend)"
  );
  process.exit(1);
}

if (/\bCLUSTER\.mongodb\.net\b/i.test(MONGO_URI)) {
  console.error(
    "MONGO_URI encore sur le modele d'exemple : l'hote « CLUSTER.mongodb.net » n'existe pas.\n" +
      "Dans Atlas : Connect → Drivers → copiez l'URI reelle (ex. xxx.sw3x05v.mongodb.net), remplacez <password>."
  );
  process.exit(1);
}

mongoose
  .connect(MONGO_URI)
  .then(async () => {
    console.log("MongoDB Connected");
    isMongoConnected = true;
    _resolvedAlertsCollection = null;
    await seedDemoChantierAssignmentsIfEmpty();
    try {
      await getResolvedAlertsCollectionName();
    } catch (e) {
      console.warn("[api] résolution collection alertes :", e.message || e);
    }
  })
  .catch((err) => {
    console.error("MongoDB connection error:", err.message || err);
    isMongoConnected = false;
  });

app.get("/api/health", async (_req, res) => {
  let alertsDataCollection = NOTIFICATIONS_ALERT_COLLECTION;
  if (isMongoConnected && mongoose.connection.db) {
    try {
      alertsDataCollection = await getResolvedAlertsCollectionName();
    } catch (_) {
      /* garde la valeur configurée */
    }
  }
  res.json({
    status: "ok",
    mongoConnected: isMongoConnected,
    service: "intervenant-backend",
    /** Liste / détail / PATCH Mongo `problemes_de_voirie` (écran mobile Problèmes voirie). */
    problemesVoirieApi: true,
    /** Si absent sur une vieille instance, l’app sait que le port est pris par un autre binaire. */
    notificationsApi: true,
    /** Nom configuré dans .env */
    notificationsSourceCollection: NOTIFICATIONS_ALERT_COLLECTION,
    /** Collection réellement utilisée si repli alert ↔ alerts (vide = messages dans les logs). */
    alertsDataCollection,
  });
});

/** Documents normalisés pour l’API (tableau ou clé `items`) — collection `alerts` (tout le contenu, sans filtre userId : les alertes météo sont globales). */
async function fetchNotificationsIntervenantApiItems(req) {
  const limitRaw = Number.parseInt(String(req.query.limit ?? "200"), 10);
  const limit = Number.isFinite(limitRaw) ? Math.min(Math.max(limitRaw, 1), 500) : 200;
  const coll = await alertsNativeCollection();
  const items = await coll
    .aggregate([
    {
      $addFields: {
        _sortDate: {
          $ifNull: [
            "$createdAt",
              {
                $ifNull: [
                  "$date_creation",
                  { $ifNull: ["$created_at", { $ifNull: ["$detected_at", { $ifNull: ["$timestamp", null] }] }] },
                ],
              },
          ],
        },
      },
    },
    { $sort: { _sortDate: -1 } },
    { $limit: limit },
    ])
    .toArray();
  return items.map((doc) => {
    const { _sortDate, ...rest } = doc;
    return notificationToApi(rest);
  });
}

async function aggregateNotificationIntervenantSorted(match, limit) {
  const items = await Notification.aggregate([
    { $match: match },
    {
      $addFields: {
        _sortDate: {
          $ifNull: [
            "$createdAt",
            { $ifNull: ["$date_creation", { $ifNull: ["$created_at", null] }] },
          ],
        },
      },
    },
    { $sort: { _sortDate: -1 } },
    { $limit: limit },
  ]);
  return items.map(({ _sortDate, ...rest }) => rest);
}

async function aggregateActiveAlertsSorted(limit) {
  const coll = await alertsNativeCollection();
  const items = await coll
    .aggregate([
      {
        $addFields: {
          _sortDate: {
            $ifNull: [
              "$createdAt",
              {
                $ifNull: [
                  "$date_creation",
                  { $ifNull: ["$created_at", { $ifNull: ["$detected_at", { $ifNull: ["$timestamp", null] }] }] },
                ],
              },
            ],
          },
        },
      },
      { $sort: { _sortDate: -1 } },
      { $limit: limit },
    ])
    .toArray();
  return items.map(({ _sortDate, ...rest }) => rest);
}

/** Tri prioritaire `timestamp` (comme Atlas), puis dates usuelles — toute la collection configurée (ex. `alerts`). */
async function aggregateAllAlertsSortedByTimestamp(limit) {
  const coll = await alertsNativeCollection();
  const items = await coll
    .aggregate([
      {
        $addFields: {
          _sortDate: {
            $ifNull: [
              "$timestamp",
              {
                $ifNull: [
                  "$created_at",
                  {
                    $ifNull: [
                      "$createdAt",
                      { $ifNull: ["$date_creation", { $ifNull: ["$detected_at", null] }] },
                    ],
                  },
                ],
              },
            ],
          },
        },
      },
      { $sort: { _sortDate: -1 } },
      { $limit: limit },
    ])
    .toArray();
  return items.map(({ _sortDate, ...rest }) => rest);
}

/**
 * GET /api/alerts ou GET /api/alert — même handler.
 * URL API : pluriel recommandé (`/api/alerts`) ; singulier = alias (collection Atlas peut s’appeler `alert`).
 */
async function handlePublicAlertsList(req, res) {
  if (!isMongoConnected) {
    return res.status(503).json({ error: "Base indisponible." });
  }
  try {
    const limitRaw = Number.parseInt(String(req.query.limit ?? "200"), 10);
    const limit = Number.isFinite(limitRaw) ? Math.min(Math.max(limitRaw, 1), 500) : 200;
    const docs = await aggregateAllAlertsSortedByTimestamp(limit);
    const out = docs.map((doc) => ({
      ...notificationToApi(doc),
      feedType: "alert",
    }));
    return res.json(out);
  } catch (err) {
    return res.status(500).json({ error: err.message || String(err) });
  }
}

/**
 * GET /api/notifications/:intervenantId — flux unifié : `notification_intervenant` (filtré) + collection alertes (toutes les docs).
 * Query optionnelle : ?intervenantId=interv_001&email=…&limit=200 (clés additionnelles pour le filtre problèmes).
 */
async function handleUnifiedNotificationsFeed(req, res) {
  if (!isMongoConnected) {
    return res.status(503).json({ success: false, message: "Base indisponible." });
  }
  try {
    const paramKey = decodeURIComponent(String(req.params.intervenantId || "")).trim();
    const extra = String(req.query.intervenantId || req.query.altIntervenantId || "").trim();
    const emailQ = String(req.query.email || "").trim().toLowerCase();
    const rawIds = [paramKey, extra, emailQ].filter(Boolean);

    const limitRaw = Number.parseInt(String(req.query.limit ?? "200"), 10);
    const limit = Number.isFinite(limitRaw) ? Math.min(Math.max(limitRaw, 1), 500) : 200;

    const problemMatch = notificationMultiUserQuery(rawIds);

    const [problemDocs, alertDocs] = await Promise.all([
      problemMatch ? aggregateNotificationIntervenantSorted(problemMatch, limit) : Promise.resolve([]),
      aggregateActiveAlertsSorted(limit),
    ]);

    const formattedProblems = problemDocs.map((doc) => ({
      ...notificationToApi(doc),
      feedType: "problem",
    }));
    const formattedAlerts = alertDocs.map((doc) => ({
      ...notificationToApi(doc),
      feedType: "alert",
    }));

    const all = [...formattedProblems, ...formattedAlerts];
    all.sort((a, b) => {
      const da = new Date(a.createdAt).getTime();
      const db = new Date(b.createdAt).getTime();
      return db - da;
    });
    const items = all.slice(0, limit);

    const unreadQ = notificationMultiUnreadQuery(rawIds);
    const ac = await alertsNativeCollection();
    const [unreadProblems, unreadAlerts] = await Promise.all([
      unreadQ ? Notification.countDocuments(unreadQ) : Promise.resolve(0),
      ac.countDocuments(alertUnreadOnlyFilter()),
    ]);
    const unreadCount = unreadProblems + unreadAlerts;

    return res.json({ success: true, items, unreadCount });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Erreur flux notifications unifie.",
      details: error.message,
    });
  }
}

/** GET /api/notifications — JSON enveloppé { success, items, unreadCount }. */
async function handleNotificationsListWrapped(req, res) {
  if (!isMongoConnected) {
    return res.status(503).json({ success: false, message: "Base indisponible." });
  }
  try {
    const userId = String(req.query.userId || req.query.email || "")
      .trim()
      .toLowerCase();
    const apiItems = await fetchNotificationsIntervenantApiItems(req);
    const unreadProblems = userId
      ? await Notification.countDocuments(notificationUnreadQuery(userId))
      : await Notification.countDocuments({
          $and: [
            { isRead: { $ne: true } },
            { lu: { $ne: true } },
            { read: { $ne: true } },
          ],
        });
    const ac = await alertsNativeCollection();
    const unreadAlerts = await ac.countDocuments(alertUnreadOnlyFilter());
    const unreadCount = unreadProblems + unreadAlerts;
    return res.json({
      success: true,
      items: apiItems,
      unreadCount,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Erreur lecture notifications.",
      details: error.message,
    });
  }
}

/**
 * GET /api/notifications-intervenant — tableau JSON brut (comme find().sort()),
 * filtre optionnel ?userId= / ?email=, sinon toute la collection.
 */
async function handleNotificationsIntervenantSimpleArray(req, res) {
  if (!isMongoConnected) {
    return res.status(503).json({ message: "Base indisponible." });
  }
  try {
    const apiItems = await fetchNotificationsIntervenantApiItems(req);
    return res.json(apiItems);
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
}

/** Notifications : routes enregistrées tôt pour éviter tout conflit avec d’autres middlewares. */
app.get("/api/alerts", handlePublicAlertsList);
app.get("/api/alert", handlePublicAlertsList);
app.get("/api/notifications", handleNotificationsListWrapped);
app.get("/api/notifications-intervenant", handleNotificationsIntervenantSimpleArray);

app.get("/api/notifications/unread-count", async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({ success: false, message: "Base indisponible." });
  }
  try {
    const userId = String(req.query.userId || req.query.email || "")
      .trim()
      .toLowerCase();
    const unreadProblems = userId
      ? await Notification.countDocuments(notificationUnreadQuery(userId))
      : await Notification.countDocuments({
          $and: [
            { isRead: { $ne: true } },
            { lu: { $ne: true } },
            { read: { $ne: true } },
          ],
        });
    const ac2 = await alertsNativeCollection();
    const unreadAlerts = await ac2.countDocuments(alertUnreadOnlyFilter());
    const unreadCount = unreadProblems + unreadAlerts;
    return res.json({ success: true, unreadCount });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Erreur compteur notifications.",
      details: error.message,
    });
  }
});

/** Flux unifié (problèmes + alertes) — après /unread-count pour ne pas capturer ce segment. */
app.get("/api/notifications/:intervenantId", handleUnifiedNotificationsFeed);

app.patch("/api/notifications/:id/read", async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({ success: false, message: "Base indisponible." });
  }
  try {
    const userId = String(req.body?.userId || req.body?.email || "")
      .trim()
      .toLowerCase();
    const id = String(req.params.id || "").trim();
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ success: false, message: "id invalide." });
    }
    const oid = new mongoose.Types.ObjectId(id);
    const problemFilter = userId
      ? { $and: [{ _id: oid }, notificationUserQuery(userId)] }
      : { _id: oid };
    const coll = await alertsNativeCollection();
    let rawAlert = await coll.findOneAndUpdate(
      { _id: oid },
      { $set: { isRead: true, lu: true, read: true } },
      { returnDocument: "after" }
    );
    const updatedAlert = rawAlert && rawAlert.value !== undefined ? rawAlert.value : rawAlert;
    if (updatedAlert) {
      return res.json({
        success: true,
        item: { ...notificationToApi(updatedAlert), feedType: "alert" },
      });
    }
    const updated = await Notification.findOneAndUpdate(
      problemFilter,
      { $set: { isRead: true, lu: true, read: true } },
      { new: true }
    ).lean();
    if (!updated) {
      return res.status(404).json({ success: false, message: "Notification introuvable." });
    }
    return res.json({
      success: true,
      item: { ...notificationToApi(updated), feedType: "problem" },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Erreur mise a jour notification.",
      details: error.message,
    });
  }
});

app.post("/api/notifications/mark-all-read", async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({ success: false, message: "Base indisponible." });
  }
  try {
    const userId = String(req.body?.userId || req.body?.email || "")
      .trim()
      .toLowerCase();
    const filter = userId ? notificationUserQuery(userId) : {};
    const acMark = await alertsNativeCollection();
    const [rAlert, rProblem] = await Promise.all([
      acMark.updateMany(alertUnreadOnlyFilter(), { $set: { isRead: true, lu: true, read: true } }),
      Notification.updateMany(filter, { $set: { isRead: true, lu: true, read: true } }),
    ]);
    const modifiedCount = (rAlert.modifiedCount ?? 0) + (rProblem.modifiedCount ?? 0);
    return res.json({ success: true, modifiedCount });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Erreur marquer tout comme lu.",
      details: error.message,
    });
  }
});

app.delete("/api/notifications/:id", async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({ success: false, message: "Base indisponible." });
  }
  try {
    const userId = String(req.query.userId || req.query.email || "")
      .trim()
      .toLowerCase();
    if (!userId) {
      return res.status(400).json({ success: false, message: "Parametre requis: userId" });
    }
    const id = String(req.params.id || "").trim();
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ success: false, message: "id invalide." });
    }
    const oidDel = new mongoose.Types.ObjectId(id);
    const q = { $and: [{ _id: oidDel }, notificationUserQuery(userId)] };
    const acDel = await alertsNativeCollection();
    let deleted = await acDel.findOneAndDelete({ _id: oidDel });
    if (!deleted) {
      deleted = await Notification.findOneAndDelete(q);
    }
    if (!deleted) {
      return res.status(404).json({ success: false, message: "Notification introuvable." });
    }
    return res.json({ success: true });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Erreur suppression notification.",
      details: error.message,
    });
  }
});

// Certains outils / onglets appellent cette route via le tunnel ; évite le bruit 404 dans ngrok.
app.get("/alert/stream", (_req, res) => {
  res.status(200).type("text/plain").send("");
});

/** Aide au débogage (téléphone / navigateur) : confirme que c’est bien ce serveur Node. */
app.get("/", (_req, res) => {
  res.json({
    service: "intervenant-backend",
    health: "/api/health",
    notificationsSourceCollection: NOTIFICATIONS_ALERT_COLLECTION,
    notificationsIntervenant:
      `GET /api/notifications-intervenant → tableau JSON depuis la collection « ${NOTIFICATIONS_ALERT_COLLECTION} » (tri date desc, ?userId= optionnel)`,
    notificationsWrapped:
      `GET /api/notifications → { success, items, unreadCount } (alertes « ${NOTIFICATIONS_ALERT_COLLECTION} » seules)`,
    notificationsUnified:
      "GET /api/notifications/:intervenantId → { success, items, unreadCount } (problèmes filtrés + alertes) ; query ?intervenantId= & ?email=",
    alerts:
      "GET /api/alerts?limit=200 — alias GET /api/alert (singulier) ; même réponse. " +
        `La collection Mongo lue est résolue automatiquement (ex. alert vs alerts), indépendamment du chemin API.`,
    assignments: "/api/intervenant/assignments",
    assignmentsAlias: "/api/assignments",
    assignmentStatusPatch: "PATCH /api/intervenant/assignments/:id/status { status }",
    problemesVoirie: `GET /api/problemes-voirie?team_label=&team_key= → collection « ${PROBLEMES_VOIRIE_COLLECTION} »`,
    problemeVoirieDetail: "GET /api/problemes-voirie/:id",
    problemeVoiriePatch: "PATCH /api/problemes-voirie/:id { status }",
  });
});

async function listIntervenantAssignments(req, res) {
  if (!isMongoConnected) {
    return res.status(503).json({
      success: false,
      message: "Base indisponible.",
      items: [],
      limit: 0,
    });
  }
  try {
    const limitRaw = Number.parseInt(String(req.query.limit ?? "200"), 10);
    const limit = Number.isFinite(limitRaw) ? Math.min(Math.max(limitRaw, 1), 500) : 200;
    const teamLabel = String(req.query.team_label || "").trim();
    const teamKey = String(req.query.team_key || "").trim();
    const filter = assignmentMongoFilter(teamLabel, teamKey);
    const docs = await ChantierAssignment.find(filter).sort({ updated_at: -1 }).limit(limit).exec();
    res.json({
      success: true,
      message: "OK",
      items: docs.map((d) => assignmentDocToApiItem(d)),
      limit,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || "Erreur liste chantiers.",
      items: [],
      limit: 0,
    });
  }
}

async function patchIntervenantAssignmentStatus(req, res) {
  if (!isMongoConnected) {
    return res.status(503).json({ success: false, message: "Base indisponible." });
  }
  try {
    const id = String(req.params.id || "").trim();
    if (!id || !mongoose.isValidObjectId(id)) {
      return res.status(400).json({ success: false, message: "id invalide." });
    }
    const normalized = normalizeAssignmentStatusInput(req.body?.status);
    if (!normalized) {
      return res.status(400).json({
        success: false,
        message:
          "Statut invalide. Valeurs : assigné, en_cours, en_pause, terminé.",
      });
    }
    const doc = await ChantierAssignment.findByIdAndUpdate(
      id,
      { $set: { status: normalized } },
      { new: true }
    ).exec();
    if (!doc) {
      return res.status(404).json({ success: false, message: "Chantier introuvable." });
    }
    return res.json({
      success: true,
      message: "OK",
      item: assignmentDocToApiItem(doc),
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || "Mise à jour impossible.",
    });
  }
}

async function listProblemesVoirie(req, res) {
  if (!isMongoConnected) {
    return res.status(503).json({
      success: false,
      message: "Base indisponible.",
      items: [],
      limit: 0,
    });
  }
  try {
    const limit = problemesVoirieListLimit(req);
    const teamLabel = String(req.query.team_label || req.query.equipe || "").trim();
    const teamKey = String(req.query.team_key || "").trim();
    const filter = problemesVoirieMongoFilter(teamLabel, teamKey);
    const docs = await ProblemeVoirie.find(filter)
      .sort({ updated_at: -1, date_detection: -1 })
      .limit(limit)
      .lean()
      .exec();
    return res.json({
      success: true,
      message: "OK",
      collection: PROBLEMES_VOIRIE_COLLECTION,
      items: docs.map((d) => problemeVoirieToApi(d)),
      limit,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || "Erreur liste problemes voirie.",
      items: [],
      limit: 0,
    });
  }
}

// Compat mobile: endpoint simple qui renvoie un tableau JSON brut (sans wrapper success/items).
async function listProblemesVoirieArray(req, res) {
  if (!isMongoConnected) {
    return res.status(503).json([]);
  }
  try {
    const limit = problemesVoirieListLimit(req);
    const teamLabel = String(req.query.team_label || req.query.equipe || "").trim();
    const teamKey = String(req.query.team_key || "").trim();
    const filter = teamLabel || teamKey ? problemesVoirieMongoFilter(teamLabel, teamKey) : {};
    const docs = await ProblemeVoirie.find(filter)
      .sort({ risk_score: -1 })
      .limit(limit)
      .lean()
      .exec();
    return res.json(docs.map((d) => problemeVoirieToApi(d)));
  } catch (error) {
    return res.status(500).json({ error: error.message || "Erreur liste problemes." });
  }
}

async function getProblemeVoirieById(req, res) {
  if (!isMongoConnected) {
    return res.status(503).json({ success: false, message: "Base indisponible." });
  }
  try {
    const id = String(req.params.id || "").trim();
    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({ success: false, message: "id invalide." });
    }
    const doc = await ProblemeVoirie.findById(id).lean().exec();
    if (!doc) {
      return res.status(404).json({ success: false, message: "Probleme introuvable." });
    }
    return res.json({ success: true, item: problemeVoirieToApi(doc) });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || "Erreur lecture probleme.",
    });
  }
}

/** Statuts métier persistés en Mongo (`status` / `statut`) : en attente | en cours | terminé (+ synonymes). */
function problemeVoirieNormalizeStatusInput(raw) {
  const s = String(raw || "")
    .trim()
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/\s+/g, " ");
  if (!s) return "";
  if (s.includes("attente") || s === "pending" || s === "assigned" || s === "nouveau" || s === "assigne") {
    return "en attente";
  }
  if (
    s.includes("termine") ||
    s === "done" ||
    s === "closed" ||
    s === "completed" ||
    s === "cloture"
  ) {
    return "terminé";
  }
  if (s.includes("cours") || s === "in_progress" || s === "processing" || s === "en_traitement") {
    return "en cours";
  }
  return "";
}

async function patchProblemeVoirie(req, res) {
  if (!isMongoConnected) {
    return res.status(503).json({ success: false, message: "Base indisponible." });
  }
  try {
    const id = String(req.params.id || "").trim();
    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({ success: false, message: "id invalide." });
    }
    const incoming = String(req.body?.status ?? req.body?.statut ?? "").trim();
    if (!incoming) {
      return res.status(400).json({ success: false, message: "Champ status requis." });
    }
    const normalized = problemeVoirieNormalizeStatusInput(incoming);
    const status = normalized || incoming;
    const doc = await ProblemeVoirie.findByIdAndUpdate(
      id,
      { $set: { status, statut: status, updated_at: new Date() } },
      { new: true }
    )
      .lean()
      .exec();
    if (!doc) {
      return res.status(404).json({ success: false, message: "Probleme introuvable." });
    }
    return res.json({ success: true, item: problemeVoirieToApi(doc) });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || "Mise a jour impossible.",
    });
  }
}

app.get("/api/problemes-voirie", listProblemesVoirie);
app.get("/api/problemes", listProblemesVoirieArray);
app.get("/api/problemes-voirie/:id", getProblemeVoirieById);
app.patch("/api/problemes-voirie/:id", patchProblemeVoirie);
// Alias (underscore) : mêmes handlers, utile si proxy / vieux clients.
app.get("/api/problemes_voirie", listProblemesVoirie);
app.get("/api/problemes_voirie/:id", getProblemeVoirieById);
app.patch("/api/problemes_voirie/:id", patchProblemeVoirie);

// Liste des affectations (Flutter : GET .../api/intervenant/assignments)
app.get("/api/intervenant/assignments", listIntervenantAssignments);
app.get("/api/assignments", listIntervenantAssignments);
app.patch("/api/intervenant/assignments/:id/status", patchIntervenantAssignmentStatus);
app.patch("/api/assignments/:id/status", patchIntervenantAssignmentStatus);

app.post("/api/auth/register", async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({
      message: "Service temporairement indisponible. Connexion a la base en cours ou echouee.",
    });
  }
  try {
    const nom = String(req.body?.nom || "").trim();
    const prenom = String(req.body?.prenom || "").trim();
    const equipe = String(req.body?.equipe || "").trim();
    const name = String(req.body?.name || `${nom} ${prenom}`.trim()).trim();
    const email = String(req.body?.email || "")
      .trim()
      .toLowerCase();
    const password = String(req.body?.password || "").trim();

    if (!nom || !prenom || !equipe || !email || !password) {
      return res.status(400).json({ message: "Tous les champs sont obligatoires." });
    }

    if (!email.includes("@")) {
      return res.status(400).json({ message: "Email invalide." });
    }

    if (password.length < 6) {
      return res.status(400).json({ message: "Mot de passe minimum 6 caracteres." });
    }

    const existing = await Intervenant.findOne({ email });
    if (existing) {
      return res.status(409).json({ message: "Ce compte existe deja." });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    await Intervenant.create({
      name,
      nom,
      prenom,
      equipe,
      email,
      passwordHash,
    });

    const uid = email;
    try {
      await Notification.insertMany([
        {
          userId: uid,
          title: "Nouveau problème détecté",
          message:
            "Un problème de voirie a été détecté sur votre trajet vers Sfax Centre.",
          type: "route_alert",
          isRead: false,
          createdAt: new Date(Date.now() - 5 * 60 * 1000),
        },
        {
          userId: uid,
          title: "Réponse reçue",
          message: 'Votre signalement « nid-de-poule » est en cours de traitement.',
          type: "admin_reply",
          isRead: false,
          createdAt: new Date(Date.now() - 20 * 60 * 1000),
        },
        {
          userId: uid,
          title: "Signalement accepté",
          message: "Votre signalement a été validé par l'administration.",
          type: "signalement_validated",
          isRead: true,
          createdAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
        },
        {
          userId: uid,
          title: "Nouvel itinéraire proposé",
          message: "Une route plus sûre avec moins de problèmes est disponible.",
          type: "alternative_route",
          isRead: false,
          createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
        },
      ]);
    } catch (seedErr) {
      console.warn("notifications seed (register):", seedErr.message || seedErr);
    }

    return res.status(201).json({
      message: "Compte cree avec succes.",
      user: { name, nom, prenom, equipe, email },
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(409).json({ message: "Ce compte existe deja." });
    }
    return res.status(500).json({
      message: "Erreur serveur pendant l inscription.",
      details: error.message,
    });
  }
});

app.post("/api/auth/login", async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({
      message: "Service temporairement indisponible. Connexion a la base en cours ou echouee.",
    });
  }
  try {
    const email = String(req.body?.email || "")
      .trim()
      .toLowerCase();
    const password = String(req.body?.password || "").trim();

    if (!email || !password) {
      return res.status(400).json({ message: "Email et mot de passe obligatoires." });
    }

    const user = await Intervenant.findOne({ email });
    if (!user) {
      return res.status(401).json({ message: "Identifiants invalides." });
    }

    const isValid = await bcrypt.compare(password, user.passwordHash);
    if (!isValid) {
      return res.status(401).json({ message: "Identifiants invalides." });
    }

    return res.json({
      message: "Connexion reussie.",
      user: {
        name: user.name,
        nom: user.nom,
        prenom: user.prenom,
        equipe: user.equipe,
        email: user.email,
      },
    });
  } catch (error) {
    return res.status(500).json({
      message: "Erreur serveur pendant la connexion.",
      details: error.message,
    });
  }
});

app.get("/api/profile", async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({ success: false, message: "Base indisponible." });
  }
  try {
    const email = String(req.query.email || "")
      .trim()
      .toLowerCase();
    if (!email) {
      return res.status(400).json({ success: false, message: "Parametre requis: email" });
    }
    const user = await Intervenant.findOne({ email }).lean();
    if (!user) {
      return res.status(404).json({ success: false, message: "Profil introuvable." });
    }
    return res.json({
      success: true,
      item: {
        name: user.name,
        responsable: user.responsable || `${user.nom || ""} ${user.prenom || ""}`.trim(),
        email: user.email,
        phone: user.phone || "",
        zone: user.zone || "Sfax Centre",
        role: "intervenant",
        speciality: user.speciality || user.equipe || "Voirie",
        membersCount: Number(user.membersCount || 1),
        completedChantiers: Number(user.completedChantiers || 0),
        currentChantiers: Number(user.currentChantiers || 0),
        urgentChantiers: Number(user.urgentChantiers || 0),
        avgInterventionTime: user.avgInterventionTime || "2h",
        rating: Number(user.rating || 4.5),
        profileImage: user.profileImage || "",
        notificationsEnabled: user.notificationsEnabled !== false,
        darkModeEnabled: user.darkModeEnabled === true,
        preferredLanguage: user.preferredLanguage || "fr",
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Erreur serveur pendant la lecture du profil.",
      details: error.message,
    });
  }
});

app.patch("/api/profile", async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({ success: false, message: "Base indisponible." });
  }
  try {
    const email = String(req.body?.email || "")
      .trim()
      .toLowerCase();
    if (!email) {
      return res.status(400).json({ success: false, message: "email obligatoire." });
    }
    const allowed = [
      "name",
      "responsable",
      "phone",
      "zone",
      "speciality",
      "membersCount",
      "profileImage",
      "notificationsEnabled",
      "darkModeEnabled",
      "preferredLanguage",
    ];
    const update = {};
    for (const key of allowed) {
      if (req.body?.[key] !== undefined) {
        update[key] = req.body[key];
      }
    }
    if (Object.keys(update).length === 0) {
      return res.status(400).json({ success: false, message: "Aucune modification fournie." });
    }
    const saved = await Intervenant.findOneAndUpdate({ email }, { $set: update }, { new: true });
    if (!saved) {
      return res.status(404).json({ success: false, message: "Profil introuvable." });
    }
    return res.json({ success: true, message: "Profil mis a jour." });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Erreur serveur pendant la mise a jour du profil.",
      details: error.message,
    });
  }
});

app.get("/api/chat/intervenant", async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({
      success: false,
      message: "Service temporairement indisponible. Connexion a la base en cours ou echouee.",
    });
  }
  try {
    const intervenantId = String(req.query.intervenant_id || "").trim();
    const hasLimit = req.query.limit !== undefined;
    const limitRaw = Number.parseInt(String(req.query.limit ?? ""), 10);
    const limit = hasLimit && Number.isFinite(limitRaw) ? Math.min(Math.max(limitRaw, 1), 5000) : null;
    if (!intervenantId) {
      return res.status(400).json({
        success: false,
        message: "Parametre requis: intervenant_id",
      });
    }
    const idCandidates = await chatParticipantIdAlternatives(intervenantId);
    const mongoFilter =
      idCandidates.length <= 1
        ? { $or: [{ intervenantId: intervenantId }, { recipient_id: intervenantId }] }
        : {
            $or: [{ intervenantId: { $in: idCandidates } }, { recipient_id: { $in: idCandidates } }],
          };
    let query = ChatIntervenant.find(mongoFilter).sort({ createdAt: 1 });
    if (limit !== null) {
      query = query.limit(limit);
    }
    const docs = await query.lean();
    return res.json({
      success: true,
      items: docs.map((doc) => ({
        id: String(doc._id),
        intervenantId: doc.intervenantId,
        intervenantName: doc.intervenantName,
        senderRole: doc.senderRole,
        sender_type: doc.sender_type,
        from_admin: doc.from_admin,
        author_label: doc.author_label,
        author_key: doc.author_key,
        text: doc.text,
        message: doc.message,
        attachments: doc.attachments || [],
        createdAt: doc.createdAt,
      })),
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Erreur serveur pendant la lecture du chat.",
      details: error.message,
    });
  }
});

// JSON message (sans fichiers)
app.post("/api/chat/intervenant", async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({
      success: false,
      message: "Service temporairement indisponible. Connexion a la base en cours ou echouee.",
    });
  }
  try {
    let intervenantId = String(req.body?.intervenantId || "").trim();
    const intervenantName = String(req.body?.intervenantName || "").trim();
    const senderRole = String(req.body?.senderRole || "").trim();
    const text = String(req.body?.text || "").trim();
    if (!intervenantId || !intervenantName || !text) {
      return res.status(400).json({
        success: false,
        message: "intervenantId, intervenantName et text sont obligatoires.",
      });
    }
    if (senderRole !== "intervenant" && senderRole !== "admin") {
      return res.status(400).json({
        success: false,
        message: "senderRole invalide. Valeurs acceptees: intervenant, admin.",
      });
    }
    intervenantId = await normalizeChatIntervenantIdForWrite(intervenantId);
    const saved = await ChatIntervenant.create({
      intervenantId,
      intervenantName,
      senderRole,
      text,
      attachments: [],
      createdAt: new Date(),
    });
    return res.status(201).json({
      success: true,
      item: {
        id: String(saved._id),
        intervenantId: saved.intervenantId,
        intervenantName: saved.intervenantName,
        senderRole: saved.senderRole,
        text: saved.text,
        attachments: saved.attachments || [],
        createdAt: saved.createdAt,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Erreur serveur pendant l'envoi du message.",
      details: error.message,
    });
  }
});

// Message + piece jointe (multipart/form-data)
app.post("/api/chat/intervenant/attachment", upload.single("file"), async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({
      success: false,
      message: "Service temporairement indisponible. Connexion a la base en cours ou echouee.",
    });
  }
  try {
    let intervenantId = String(req.body?.intervenantId || "").trim();
    const intervenantName = String(req.body?.intervenantName || "").trim();
    const senderRole = String(req.body?.senderRole || "").trim();
    const text = String(req.body?.text || "").trim();
    const file = req.file;

    if (!intervenantId || !intervenantName) {
      return res.status(400).json({
        success: false,
        message: "intervenantId et intervenantName sont obligatoires.",
      });
    }
    if (senderRole !== "intervenant" && senderRole !== "admin") {
      return res.status(400).json({
        success: false,
        message: "senderRole invalide. Valeurs acceptees: intervenant, admin.",
      });
    }
    if (!file) {
      return res.status(400).json({
        success: false,
        message: "Fichier manquant (field name: file).",
      });
    }

    intervenantId = await normalizeChatIntervenantIdForWrite(intervenantId);

    const mime = String(file.mimetype || "application/octet-stream");
    const isImage = mime.startsWith("image/");
    const kind = isImage ? "image" : mime === "application/pdf" ? "document" : "other";
    const url = `/uploads/${file.filename}`;
    const messageText = text || (isImage ? "📷 Image" : "📎 Fichier");

    const saved = await ChatIntervenant.create({
      intervenantId,
      intervenantName,
      senderRole,
      text: messageText,
      attachments: [
        {
          kind,
          name: file.originalname || file.filename,
          mime,
          size: Number(file.size || 0),
          url,
        },
      ],
      createdAt: new Date(),
    });

    return res.status(201).json({
      success: true,
      item: {
        id: String(saved._id),
        intervenantId: saved.intervenantId,
        intervenantName: saved.intervenantName,
        senderRole: saved.senderRole,
        text: saved.text,
        attachments: saved.attachments || [],
        createdAt: saved.createdAt,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Erreur serveur pendant l'envoi de la piece jointe.",
      details: error.message,
    });
  }
});

// Evite les pages HTML "Cannot GET ..." quand Flutter tape un endpoint API invalide.
app.use("/api", (req, res) => {
  res.status(404).json({
    success: false,
    message: `API route not found: ${req.method} ${req.originalUrl}`,
    available: [
      "/api/health",
      "/api/problemes-voirie",
      "/api/problemes_voirie",
      "/api/problemes-voirie/:id",
      "/api/problemes_voirie/:id",
      "/api/intervenant/assignments",
      "/api/assignments",
      "/api/auth/register",
      "/api/auth/login",
      "/api/profile",
      "/api/chat/intervenant",
      "/api/chat/intervenant/attachment",
      "/api/alerts",
      "/api/alert",
      "/api/notifications",
      "/api/notifications-intervenant",
      "/api/notifications/unread-count",
      "GET /api/notifications/:intervenantId (flux unifie: notification_intervenant + alert actives)",
      "/api/notifications/:id/read",
      "/api/notifications/mark-all-read",
    ],
  });
});

/** Adresses IPv4 locales (toutes interfaces utiles) pour l’app mobile sur le même réseau. */
function printLanAccessUrls(portNum) {
  const nets = os.networkInterfaces();
  const ipv4 = [];
  for (const name of Object.keys(nets || {})) {
    for (const net of nets[name] || []) {
      const fam = net.family;
      if ((fam === "IPv4" || fam === 4) && net.internal === false) {
        ipv4.push(net.address);
      }
    }
  }
  if (ipv4.length === 0) {
    console.log("(Aucune IPv4 locale trouvee : utilisez ipconfig / ifconfig pour l'IP du PC.)");
    return;
  }
  console.log("Tester depuis le navigateur du telephone (meme Wi‑Fi) :");
  for (const ip of ipv4) {
    console.log(`  http://${ip}:${portNum}/api/health`);
  }
}

/** Port demandé dans backend/.env ; défaut 3000 (Flutter : lib/constants/backend_defaults.dart). */
const preferredPort = Number(process.env.PORT || 3000);
/** Défaut 1 : même port que ngrok (`ngrok http 3000`). Augmentez si vous acceptez PORT+1… */
const portTryCount = Math.max(1, Math.min(50, Number(process.env.PORT_TRY_COUNT || 1)));

function logStartupBanner(actualPort) {
  console.log(`Backend intervenant listening on http://localhost:${actualPort}`);
  console.log(`Ecoute sur toutes les interfaces (0.0.0.0), port ${actualPort}.`);
  printLanAccessUrls(actualPort);
  console.log(`Test rapide sur ce PC : GET http://localhost:${actualPort}/api/health`);
  console.log(
    `[api] problemes voirie → GET /api/problemes-voirie (collection « ${PROBLEMES_VOIRIE_COLLECTION} ») ; health doit montrer problemesVoirieApi: true`,
  );
  console.log(
    `[api] notifications → collection MongoDB « ${NOTIFICATIONS_ALERT_COLLECTION} » (pas notification_intervenant)`
  );
  console.log(
    "Si /api/notifications repond 404 : un autre programme peut occuper le port "
      + `(netstat -ano | findstr :${actualPort} sous Windows, puis taskkill /PID … /F).`,
  );
}

/**
 * Tente d’écouter sur [port]. Retourne true si démarrage OK.
 * Évite le crash quand 3000 est déjà pris (ancien Node) : le parent peut réessayer port+1.
 */
function tryListenOnPort(port) {
  return new Promise((resolve) => {
    const srv = http.createServer(app);
    let listenCallbackRan = false;
    let settled = false;
    const finish = (ok) => {
      if (settled) return;
      settled = true;
      resolve(ok);
    };

    srv.on("error", (err) => {
      const code = err && err.code;
      if (!listenCallbackRan) {
        if (code === "EADDRINUSE") {
          try {
            srv.close();
          } catch (_) {
            /* ignore */
          }
          finish(false);
          return;
        }
        console.error("[FATAL] serveur HTTP:", err.message || err);
        process.exit(1);
      }
      if (code === "EADDRINUSE") {
        console.error(
          `[warn] Evenement EADDRINUSE apres demarrage reussi (port ${port}). Verifiez qu'un seul service ecoute ce port.`,
        );
        return;
      }
      console.error("[warn] erreur serveur HTTP:", err.message || err);
    });

    srv.listen(port, "0.0.0.0", () => {
      listenCallbackRan = true;
      logStartupBanner(port);
      finish(true);
    });
  });
}

async function startHttpServer() {
  for (let i = 0; i < portTryCount; i++) {
    const port = preferredPort + i;
    const ok = await tryListenOnPort(port);
    if (ok) {
      if (i > 0) {
        console.warn(
          `[info] Port ${preferredPort} etait occupe — serveur demarre sur ${port}. ` +
            `Mettez http://<IP_PC_WIFI>:${port} dans l'app. Pour n'utiliser que ${preferredPort} : liberez le port (taskkill) ou PORT_TRY_COUNT=1 dans .env.`,
        );
      }
      return;
    }
    if (i === 0) {
      console.warn(
        `[info] Port ${preferredPort} occupe — essai automatique ${preferredPort + 1} … ${preferredPort + portTryCount - 1} …`,
      );
    }
  }
  console.error(
    `[FATAL] Aucun port libre entre ${preferredPort} et ${preferredPort + portTryCount - 1}. ` +
      `Windows : netstat -ano | findstr :${preferredPort} puis taskkill /PID … /F`,
  );
  process.exit(1);
}

startHttpServer().catch((err) => {
  console.error(err);
  process.exit(1);
});
