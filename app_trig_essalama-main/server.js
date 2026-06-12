const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const os = require("os");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");
const { OAuth2Client } = require("google-auth-library");
const jwksClient = require('jwks-rsa');
const crypto = require('crypto');
const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");
const turf = require("@turf/turf");

const app = express();

app.use(cors());
app.use(express.json({ limit: "25mb" })); // pour photo de profil/captures en base64

// 🔹 Connexion MongoDB
const MONGO_URI =
  "mongodb+srv://oumaymabenna2_db_user:Test123456@trigessalama.sw3x05v.mongodb.net/trig_essalama?retryWrites=true&w=majority";

// Variable pour suivre l'état de la connexion MongoDB
let isMongoConnected = false;

mongoose
  .connect(MONGO_URI)
  .then(async () => {
    console.log("✅ MongoDB Connected");
    isMongoConnected = true;
    await backfillProblemeSignalePositions();
    initFirebaseAdminIfConfigured();
    startAlertMongoWatch();
  })
  .catch((err) => {
    console.error("❌ MongoDB connection error:", err);
    isMongoConnected = false;
  });

/** Initialise Firebase Admin si une clé de compte de service est fournie (fichier ou JSON en env). */
function initFirebaseAdminIfConfigured() {
  if (admin.apps.length > 0) return true;
  try {
    const jsonEnv = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
    if (jsonEnv && jsonEnv.trim()) {
      const parsed = JSON.parse(jsonEnv);
      admin.initializeApp({ credential: admin.credential.cert(parsed) });
      console.log("✅ Firebase Admin initialisé (FIREBASE_SERVICE_ACCOUNT_JSON)");
      return true;
    }
    const credPath =
      process.env.GOOGLE_APPLICATION_CREDENTIALS ||
      process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
    if (credPath && credPath.trim()) {
      const resolved = path.isAbsolute(credPath)
        ? credPath
        : path.join(__dirname, credPath);
      if (!fs.existsSync(resolved)) {
        console.warn(
          "⚠️ Fichier de clé Firebase introuvable:",
          resolved,
          "— notifications push désactivées."
        );
        return false;
      }
      // ADC lit GOOGLE_APPLICATION_CREDENTIALS (chemin absolu recommandé)
      process.env.GOOGLE_APPLICATION_CREDENTIALS = path.resolve(resolved);
      admin.initializeApp({
        credential: admin.credential.applicationDefault(),
      });
      console.log(
        "✅ Firebase Admin initialisé (applicationDefault ←",
        process.env.GOOGLE_APPLICATION_CREDENTIALS,
        ")"
      );
      return true;
    }
    const defaultKeyFile = path.join(__dirname, "firebase-service-account.json");
    if (fs.existsSync(defaultKeyFile)) {
      const raw = fs.readFileSync(defaultKeyFile, "utf8");
      const parsed = JSON.parse(raw);
      admin.initializeApp({ credential: admin.credential.cert(parsed) });
      console.log(
        "✅ Firebase Admin initialisé (fichier local firebase-service-account.json)"
      );
      return true;
    }
    const fcmHint =
      "FCM désactivé : ajoutez firebase-service-account.json à côté de server.js, " +
      "ou définissez FIREBASE_SERVICE_ACCOUNT_JSON / GOOGLE_APPLICATION_CREDENTIALS / FIREBASE_SERVICE_ACCOUNT_PATH.";
    if (process.env.NODE_ENV === "production") {
      console.warn("⚠️ Firebase Admin —", fcmHint);
    } else {
      console.log("ℹ️ Firebase Admin —", fcmHint, "(OK en local si vous n’utilisez pas les push.)");
    }
    return false;
  } catch (e) {
    console.error("❌ initFirebaseAdminIfConfigured:", e.message);
    return false;
  }
}

let alertWatchStarted = false;

/** Clients SSE connectés : reçoivent un événement à chaque insertion dans `alert`. */
const alertSseClients = new Set();

function broadcastAlertSse(alertDoc) {
  const id =
    alertDoc && alertDoc._id != null ? String(alertDoc._id) : "";
  // On envoie le document complet pour permettre une mise à jour immédiate côté app
  const data = JSON.stringify({
    event: "insert",
    id: id,
    fullDocument: alertDoc, // Ajout du document complet
  });
  const line = `data: ${data}\n\n`;
  for (const res of [...alertSseClients]) {
    try {
      if (!res.writableEnded) res.write(line);
    } catch (_) {
      alertSseClients.delete(res);
    }
  }
}

const FCM_MULTICAST_CHUNK = 500;

/** Envoie une notification identique à plusieurs tokens (batch FCM). */
async function sendAlertMulticastToTokens(entries, title, body, alertDoc) {
  if (!entries.length) return;
  const tokens = entries.map((e) => e.token);
  const userIds = entries.map((e) => e.userId);

  // Payload standardisé correspondant à la structure SSE
  const fcmData = {
    type: "alert",
    alertId: alertDoc._id != null ? String(alertDoc._id) : "",
    title: title,
    body: String(body).slice(0, 500),
    priority: alertDoc.priority != null ? String(alertDoc.priority) : "normal",
    timestamp: (alertDoc.created_at || alertDoc.timestamp || new Date()).toString(),
    fullDocument: JSON.stringify(alertDoc),
  };

  const message = {
    notification: { title, body },
    data: fcmData,
    android: {
      notification: {
        clickAction: "FLUTTER_NOTIFICATION_CLICK",
        // Sons personnalisés selon la priorité
        sound: alertDoc.priority === "high" ? "urgent" : "default",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: alertDoc.priority === "high" ? "urgent.caf" : "default",
          contentAvailable: true,
        },
      },
    },
  };

  for (let offset = 0; offset < tokens.length; offset += FCM_MULTICAST_CHUNK) {
    const slice = tokens.slice(offset, offset + FCM_MULTICAST_CHUNK);
    const idsSlice = userIds.slice(offset, offset + FCM_MULTICAST_CHUNK);
    let response;
    try {
      response = await admin.messaging().sendEachForMulticast({
        tokens: slice,
        ...message,
      });
    } catch (err) {
      console.error("FCM sendEachForMulticast:", err.message || err);
      continue;
    }
    for (let i = 0; i < response.responses.length; i++) {
      const resp = response.responses[i];
      if (resp.success) continue;
      const err = resp.error;
      const code = err?.code || err?.errorInfo?.code;
      if (
        code === "messaging/invalid-registration-token" ||
        code === "messaging/registration-token-not-registered"
      ) {
        const uid = idsSlice[i];
        if (uid) {
          try {
            await User.updateOne({ _id: uid }, { $unset: { fcmToken: 1 } });
          } catch (cleanupErr) {
            console.error("FCM token cleanup:", cleanupErr.message || cleanupErr);
          }
        }
      } else {
        console.error("FCM multicast error:", err?.message || err);
      }
    }
  }
}

/** Change stream sur `alert` : SSE vers l’app + FCM si Firebase Admin est configuré. */
function startAlertMongoWatch() {
  if (alertWatchStarted) return;
  if (!isMongoConnected) return;
  try {
    const stream = AlertModel.watch();
    alertWatchStarted = true;
    stream.on("change", async (change) => {
      console.log("CHANGE DETECTED:", change);
      if (change.operationType !== "insert") return;
      const alertDoc = change.fullDocument || {};
      broadcastAlertSse(alertDoc);

      if (admin.apps.length === 0) return;

      const bodyText =
        alertDoc.message ||
        alertDoc.body ||
        alertDoc.text ||
        alertDoc.title ||
        "Nouvelle alerte";
      const priority = alertDoc.priority;
      const title =
        priority === "high"
          ? "🚨 DANGER"
          : priority === "low"
            ? "ℹ️ Info"
            : "🔔 Nouvelle alerte";
      try {
        const users = await User.find({
          fcmToken: { $exists: true, $nin: [null, ""] },
        }).lean();
        const payload = String(bodyText).slice(0, 500);
        const alertIdStr =
          alertDoc._id != null ? String(alertDoc._id) : "";
        const payloadText = String(bodyText).slice(0, 500);
        const entries = users
          .filter((u) => u.fcmToken)
          .map((u) => ({ userId: u._id, token: u.fcmToken }));
        await sendAlertMulticastToTokens(entries, title, payloadText, alertDoc);
      } catch (err) {
        console.error("alert FCM handler:", err);
      }
    });
    stream.on("error", (err) => {
      console.error("AlertModel.watch error:", err);
      alertWatchStarted = false;
    });
    console.log(
      "✅ Change stream `alert` actif (SSE temps réel + FCM si Firebase configuré)"
    );
  } catch (e) {
    console.error("startAlertMongoWatch:", e.message);
  }
}

// 🔹 Configuration JWT
const JWT_SECRET = "trig_essalama_super_secret_key_2024";

// Helper pour générer un token JWT
const generateToken = (userId) => {
  return jwt.sign({ id: userId }, JWT_SECRET, { expiresIn: "30d" });
};

// 🔐 Middleware de protection des routes par JWT
const authMiddleware = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      return res.status(401).json({
        success: false,
        message: "Token manquant",
      });
    }

    // Format: Bearer TOKEN
    const token = authHeader.split(" ")[1];

    if (!token) {
      return res.status(401).json({
        success: false,
        message: "Token invalide",
      });
    }

    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded; // On stocke les infos du token (ex: id) dans req.user
    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: "Token expiré ou invalide",
    });
  }
};

// 🔐 Variante non bloquante: décode le token si présent, sinon continue.
const optionalAuthMiddleware = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader) {
      req.user = null;
      return next();
    }
    const token = authHeader.split(" ")[1];
    if (!token) {
      req.user = null;
      return next();
    }
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    return next();
  } catch (_) {
    req.user = null;
    return next();
  }
};

// 🔹 Configuration Google Auth
const GOOGLE_CLIENT_ID = "575819831562-imrr8u7d98lrhcct53fgcc2saj9m2iql.apps.googleusercontent.com";
const client = new OAuth2Client(GOOGLE_CLIENT_ID);

// 🔹 Configuration JWKS pour Apple
const appleJwksClient = jwksClient({
  jwksUri: 'https://appleid.apple.com/auth/keys'
});

async function verifyGoogleToken(idToken) {
  const ticket = await client.verifyIdToken({
    idToken,
    audience: GOOGLE_CLIENT_ID,
  });
  return ticket.getPayload();
}

// 🔹 Schema (collection user_citoyen)
const UserSchema = new mongoose.Schema(
  {
    fullName: String,
    email: String,
    password: String,
    phone: String,
    location: String,
    profileImage: String,
    dateOfBirth: Date,
    gender: String,
    cityRegion: String,
    safetyScore: Number,
    tripsCount: { type: Number, default: 0 },
    provider: { type: String, default: "local" },
    providerId: { type: String, default: null },
    lastLogin: { type: Date, default: Date.now },
    /** Jeton FCM pour notifications push (mis à jour par l’app) */
    fcmToken: { type: String, default: null },
    createdAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    collection: "user_citoyen",
  }
);

// 🔹 Model
const User = mongoose.model("UserCitoyen", UserSchema);

// 🔹 Schema contacts d'urgence
const EmergencyContactSchema = new mongoose.Schema(
  {
    userId: { type: String, required: true },
    name: { type: String, required: true },
    phone: { type: String, required: true },
    relationship: { type: String, required: true },
    email: { type: String, default: "" },
    isPrimary: { type: Boolean, default: false },
    createdAt: { type: Date, default: Date.now },
  },
  { collection: "emergency_contacts" }
);
const EmergencyContactModel = mongoose.model("EmergencyContact", EmergencyContactSchema);

// 🔹 Schema avis / feedback utilisateur
const FeedbackSchema = new mongoose.Schema(
  {
    userId: { type: String, required: true },
    rating: { type: Number, required: true, min: 1, max: 5 },
    comment: { type: String, default: "" },
    createdAt: { type: Date, default: Date.now },
  },
  { collection: "user_feedback" }
);
const FeedbackModel = mongoose.model("UserFeedback", FeedbackSchema);

// 🔹 Schema captures caméra (photo + géolocalisation)
const CameraCaptureSchema = new mongoose.Schema(
  {
    userId: { type: String, required: true, index: true },
    imageBase64: { type: String, required: true },
    latitude: { type: Number, required: true },
    longitude: { type: Number, required: true },
    createdAt: { type: Date, default: Date.now },
  },
  { collection: "camera_captures" }
);
const CameraCaptureModel = mongoose.model("CameraCapture", CameraCaptureSchema);

// 🔹 Collection alert (documents variables : météo, routes, etc.)
const AlertSchema = new mongoose.Schema(
  {},
  { collection: "alert", strict: false }
);
const AlertModel = mongoose.model("AlertDoc", AlertSchema);

// 🔹 Collection risques (points géolocalisés : schéma flexible comme en base)
const RisqueSchema = new mongoose.Schema(
  {},
  { collection: "risques", strict: false }
);
const RisqueModel = mongoose.model("RisqueDoc", RisqueSchema);

// 🔹 Collection embouteillages
const EmbouteillageSchema = new mongoose.Schema(
  {
    location: {
      type: { type: String, enum: ["Point"], default: "Point" },
      coordinates: { type: [Number], required: true }, // [lng, lat]
    },
    latitude: { type: Number, required: true },
    longitude: { type: Number, required: true },
    level: {
      type: String,
      enum: ["light", "moderate", "heavy", "severe", "blocked"],
      default: "moderate",
      required: true,
    },
    congestionLevel: { type: Number, min: 0, max: 100, default: 50 },
    averageSpeed: { type: Number, default: 0 },
    estimatedDuration: { type: Number, default: 30 },
    cause: {
      type: String,
      enum: ["accident", "construction", "event", "peak_hour", "weather", "unknown"],
      default: "unknown",
    },
    description: { type: String, default: "" },
    radius: { type: Number, default: 100 },
    affectedRoads: [{ type: String }],
    reportCount: { type: Number, default: 1 },
    isActive: { type: Boolean, default: true },
    detectedAt: { type: Date, default: Date.now },
    expiresAt: { type: Date },
    lastUpdated: { type: Date, default: Date.now },
    source: {
      type: String,
      enum: ["user_report", "telemetry", "camera", "prediction"],
      default: "user_report",
    },
    reportedBy: { type: String, default: null },
    history: [
      {
        congestionLevel: Number,
        averageSpeed: Number,
        timestamp: Date,
      },
    ],
    tags: [{ type: String }],
  },
  {
    collection: "embouteillages",
    timestamps: { createdAt: "created_at", updatedAt: "updated_at" },
  }
);

EmbouteillageSchema.index({ location: "2dsphere" });
EmbouteillageSchema.index({ isActive: 1, level: 1 });
EmbouteillageSchema.index({ detectedAt: -1 });
// TTL index supprimé : les documents restent en base pour l'historique
// EmbouteillageSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

EmbouteillageSchema.methods.toGeoJSON = function () {
  return {
    type: "Feature",
    geometry: {
      type: "Point",
      coordinates: [this.longitude, this.latitude],
    },
    properties: {
      id: this._id,
      level: this.level,
      congestionLevel: this.congestionLevel,
      averageSpeed: this.averageSpeed,
      cause: this.cause,
      description: this.description,
      detectedAt: this.detectedAt,
    },
  };
};

EmbouteillageSchema.statics.findNearby = function (lat, lng, maxDistance = 1000) {
  return this.find({
    location: {
      $near: {
        $geometry: {
          type: "Point",
          coordinates: [lng, lat],
        },
        $maxDistance: maxDistance,
      },
    },
    isActive: true,
  });
};

EmbouteillageSchema.statics.updateOrCreate = async function (data) {
  const { latitude, longitude, congestionLevel, averageSpeed, ...rest } = data;

  /* Logique de fusion désactivée à la demande de l'utilisateur : chaque signalement crée une nouvelle entrée */
  /*
  let existing = null;
  try {
    existing = await this.findOne({
      location: {
        $near: {
          $geometry: {
            type: "Point",
            coordinates: [longitude, latitude],
          },
          $maxDistance: 50,
        },
      },
      isActive: true,
      expiresAt: { $gt: new Date() },
    });
  } catch (geoErr) {
    console.warn("Embouteillage updateOrCreate $near:", geoErr.message || geoErr);
  }

  if (existing) {
    existing.congestionLevel = congestionLevel ?? existing.congestionLevel;
    existing.averageSpeed = averageSpeed ?? existing.averageSpeed;
    existing.reportCount += 1;
    existing.lastUpdated = new Date();

    existing.history.push({
      congestionLevel: existing.congestionLevel,
      averageSpeed: existing.averageSpeed,
      timestamp: new Date(),
    });

    if (existing.history.length > 100) {
      existing.history = existing.history.slice(-100);
    }

    if (existing.congestionLevel >= 80) existing.level = "severe";
    else if (existing.congestionLevel >= 60) existing.level = "heavy";
    else if (existing.congestionLevel >= 40) existing.level = "moderate";
    else if (existing.congestionLevel >= 20) existing.level = "light";
    else existing.level = "blocked";

    await existing.save();
    return { doc: existing, merged: true };
  }
  */

  let level = "moderate";
  const cl = congestionLevel ?? 50;
  if (cl >= 80) level = "severe";
  else if (cl >= 60) level = "heavy";
  else if (cl >= 40) level = "moderate";
  else if (cl >= 20) level = "light";
  else level = "blocked";

  const jam = new this({
    location: {
      type: "Point",
      coordinates: [longitude, latitude],
    },
    latitude,
    longitude,
    congestionLevel: cl,
    averageSpeed: averageSpeed ?? 0,
    level,
    expiresAt: new Date(Date.now() + 15 * 60 * 1000), // Disparaît de la carte après 15 minutes
    history: [
      {
        congestionLevel: cl,
        averageSpeed: averageSpeed ?? 0,
        timestamp: new Date(),
      },
    ],
    ...rest,
  });
  await jam.save();
  return { doc: jam, merged: false };
};

const EmbouteillageModel = mongoose.model("Embouteillage", EmbouteillageSchema);

// 🔹 Collection accidents signalés
const AccidentSchema = new mongoose.Schema(
  {
    type: { type: String, default: "accident" },
    location: {
      lat: { type: Number, required: true },
      lng: { type: Number, required: true },
    },
    reportCount: { type: Number, default: 1 },
    confirmed: { type: Boolean, default: false },
    userIds: [{ type: String }],
    createdAt: { type: Date, default: Date.now },
    // Pas de TTL: on conserve tous les signalements en base MongoDB Atlas.
    expiresAt: { type: Date, default: null },
  },
  { collection: "accidents" }
);
const AccidentModel = mongoose.model("Accident", AccidentSchema);
const ACCIDENT_EXPIRY_MS = 6 * 60 * 60 * 1000; // 6 heures

/** Types acceptés pour la collection unifiée `problemes_signales`. */
const PROBLEME_SIGNALE_TYPES = [
  "police",
  "voie_bloquee",
  "route_fermee",
  "danger",
  "travaux",
  "vehicule_arrete",
  "nid_de_poule",
  "fissure_chaussee",
  "objet",
  "embouteillage",
  "accident",
  "mauvais_temps",
  "probleme_carte",
];
const PROBLEME_SIGNALE_TYPE_SET = new Set(PROBLEME_SIGNALE_TYPES);

// 🔹 Collection unifiée des signalements citoyens (page d'accueil, danger, etc.)
const ProblemeSignaleSchema = new mongoose.Schema(
  {
    type: { type: String, required: true, index: true },
    latitude: { type: Number, required: true },
    longitude: { type: Number, required: true },
    /** GeoJSON pour requêtes $geoWithin / index 2dsphere (rempli à l’écriture + backfill). */
    position: new mongoose.Schema(
      {
        type: { type: String, enum: ["Point"], default: "Point" },
        coordinates: { type: [Number] },
      },
      { _id: false }
    ),
    userId: { type: String, default: null },
    source: { type: String, default: "app" },
    meta: { type: mongoose.Schema.Types.Mixed, default: {} },
    createdAt: { type: Date, default: Date.now },
  },
  { collection: "problemes_signales" }
);
ProblemeSignaleSchema.index({ createdAt: -1 });
ProblemeSignaleSchema.index({ type: 1, createdAt: -1 });
ProblemeSignaleSchema.index({ latitude: 1, longitude: 1 });
ProblemeSignaleSchema.index({ position: "2dsphere" });
const ProblemeSignaleModel = mongoose.model("ProblemeSignale", ProblemeSignaleSchema);

async function backfillProblemeSignalePositions() {
  if (!isMongoConnected) return;
  try {
    const res = await ProblemeSignaleModel.collection.updateMany(
      {
        $or: [{ position: { $exists: false } }, { position: null }],
        latitude: { $exists: true, $ne: null },
        longitude: { $exists: true, $ne: null },
      },
      [
        {
          $set: {
            position: {
              type: "Point",
              coordinates: [{ $toDouble: "$longitude" }, { $toDouble: "$latitude" }],
            },
          },
        },
      ]
    );
    if (res.modifiedCount > 0) {
      console.log(
        `[problemes_signales] GeoJSON position backfill: ${res.modifiedCount} document(s)`
      );
    }
  } catch (e) {
    console.error("[problemes_signales] GeoJSON backfill error:", e.message);
  }
}

function downsampleRouteLngLat(coords, maxPoints = 450) {
  if (!Array.isArray(coords) || coords.length <= maxPoints) return coords;
  const step = Math.max(1, Math.floor(coords.length / maxPoints));
  const out = [];
  for (let i = 0; i < coords.length; i += step) {
    out.push(coords[i]);
  }
  const last = coords[coords.length - 1];
  if (out[out.length - 1][0] !== last[0] || out[out.length - 1][1] !== last[1]) {
    out.push(last);
  }
  return out;
}

/** Buffer autour de la polyligne (GeoJSON Polygon/MultiPolygon) pour $geoWithin. */
function buildBufferedGeometryFromRouteLngLat(coords, bufferMeters) {
  const km = Math.max(0.04, Math.min(0.25, bufferMeters / 1000));
  const sample = downsampleRouteLngLat(coords, 450);
  const line = turf.lineString(sample);
  const buffered = turf.buffer(line, km, { units: "kilometers", steps: 16 });
  if (!buffered || !buffered.geometry) {
    throw new Error("Impossible de calculer le tampon (turf.buffer).");
  }
  return buffered.geometry;
}

function normalizeSignaleDocForClient(doc) {
  const o = { ...doc };
  if (
    o.position &&
    o.position.coordinates &&
    Array.isArray(o.position.coordinates) &&
    o.position.coordinates.length >= 2
  ) {
    const lng = o.position.coordinates[0];
    const lat = o.position.coordinates[1];
    if (o.longitude == null && Number.isFinite(lng)) o.longitude = lng;
    if (o.latitude == null && Number.isFinite(lat)) o.latitude = lat;
  }
  return o;
}

async function safeRecordProblemeSignale(doc) {
  if (!isMongoConnected) return null;
  try {
    const merged = { ...doc };
    if (
      merged.latitude != null &&
      merged.longitude != null &&
      !merged.position
    ) {
      merged.position = {
        type: "Point",
        coordinates: [Number(merged.longitude), Number(merged.latitude)],
      };
    }
    return await ProblemeSignaleModel.create(merged);
  } catch (e) {
    console.error("[problemes_signales]", e.message);
    return null;
  }
}

// 🔹 Collection problèmes de voirie (Atlas: souvent location.address sans GeoJSON)
const ProblemeVoirieSchema = new mongoose.Schema(
  {
    problem_type: { type: String, required: true },
    total_defects: { type: Number, default: 0 },
    location: { type: mongoose.Schema.Types.Mixed, default: {} },
    risk_score: { type: Number, default: 0 },
    severity: { type: String, default: "Moyenne" },
    confidence: { type: Number, default: 1.0 },
    date_detection: { type: Date, default: Date.now },
    description: { type: String, default: "" },
    diagnostic: { type: String },
    problem_state: { type: String },
    maintenance_priority: { type: String },
    status: { type: String, default: "Nouveau" },
  },
  { collection: "problemes_de_voirie", strict: false }
);

/** Extrait lat/lon depuis location.address ("lat: 29.3, lon: 47.9, accuracy: 212m"). */
function parseLatLngFromVoirieLocation(location) {
  if (!location || typeof location !== "object") return null;
  const coords = location.coordinates;
  if (Array.isArray(coords) && coords.length >= 2) {
    const lon = Number(coords[0]);
    const lat = Number(coords[1]);
    if (Number.isFinite(lat) && Number.isFinite(lon)) return { lat, lon };
  }
  const address = typeof location.address === "string" ? location.address : "";
  const m = address.match(/lat:\s*([\d.+-]+)\s*,\s*lon:\s*([\d.+-]+)/i);
  if (m) {
    const lat = parseFloat(m[1]);
    const lon = parseFloat(m[2]);
    if (Number.isFinite(lat) && Number.isFinite(lon)) return { lat, lon };
  }
  return null;
}

function serializeProblemeVoirieDoc(doc) {
  const o = doc && typeof doc.toObject === "function" ? doc.toObject() : { ...doc };
  o._id = o._id != null ? String(o._id) : "";
  const parsed = parseLatLngFromVoirieLocation(o.location);
  if (parsed) {
    o.location = {
      ...(o.location && typeof o.location === "object" ? o.location : {}),
      type: "Point",
      coordinates: [parsed.lon, parsed.lat],
      lat: parsed.lat,
      lon: parsed.lon,
    };
  }
  return o;
}

/** Exclut les documents `problemes_de_voirie` au statut « terminé ». */
function notTerminatedVoirieStatusClause() {
  return {
    $nor: [
      { status: { $regex: /^termin[eéée]+$/i } },
      { statut: { $regex: /^termin[eéée]+$/i } },
    ],
  };
}

function mergeMongoQuery(base, extra) {
  if (!base || Object.keys(base).length === 0) return extra;
  return { $and: [base, extra] };
}

const ProblemeVoirieModel = mongoose.model("ProblemeVoirie", ProblemeVoirieSchema);

// ==================== ROUTES ====================

// 🔹 Route HOME (pour tests ngrok)
app.get("/", (req, res) => {
  res.send("🚀 Trig Essalama API is running successfully!");
});

// 🔹 Route de test health
app.get("/health", (req, res) => {
  res.json({ 
    status: "OK", 
    mongoConnected: isMongoConnected,
    message: "Backend working fine 🚀",
    timestamp: new Date().toISOString()
  });
});

// 🔹 Liste des alertes (collection MongoDB `alert`) — utilisée par l’app Flutter
app.get("/alert", async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({
      success: false,
      message: "Service temporairement indisponible.",
      alerts: [],
    });
  }
  try {
    const limitRaw = Number(req.query.limit);
    const limit = Number.isFinite(limitRaw) ? Math.max(1, Math.min(200, Math.trunc(limitRaw))) : 100;
    const docs = await AlertModel.find({})
      .sort({ created_at: -1, timestamp: -1, _id: -1 })
      .limit(limit)
      .lean();
    return res.json({
      success: true,
      alerts: docs,
    });
  } catch (err) {
    console.error("Erreur GET /alert:", err);
    return res.status(500).json({
      success: false,
      message: "Erreur lors de la lecture des alertes.",
      alerts: [],
    });
  }
});

/** Distance géodésique (mètres) entre deux points WGS84. */
function haversineMeters(lat1, lon1, lat2, lon2) {
  const R = 6371000;
  const toRad = (d) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

/** Extrait lat/lng d’un document flexible collection `risques`. */
function extractRisqueCoords(doc) {
  if (!doc || typeof doc !== "object") return null;
  const la0 = Number(doc.latitude);
  const lo0 = Number(doc.longitude);
  if (Number.isFinite(la0) && Number.isFinite(lo0)) return { lat: la0, lng: lo0 };
  const la1 = Number(doc.lat);
  const lo1 = Number(doc.lng);
  if (Number.isFinite(la1) && Number.isFinite(lo1)) return { lat: la1, lng: lo1 };
  if (doc.location && typeof doc.location === "object") {
    const loc = doc.location;
    const la2 = Number(loc.latitude ?? loc.lat);
    const lo2 = Number(loc.longitude ?? loc.lng);
    if (Number.isFinite(la2) && Number.isFinite(lo2)) return { lat: la2, lng: lo2 };
    const coords = loc.coordinates;
    if (Array.isArray(coords) && coords.length >= 2) {
      const lo = Number(coords[0]);
      const la = Number(coords[1]);
      if (Number.isFinite(la) && Number.isFinite(lo)) return { lat: la, lng: lo };
    }
  }
  if (doc.geometry && doc.geometry.type === "Point" && Array.isArray(doc.geometry.coordinates)) {
    const c = doc.geometry.coordinates;
    if (c.length >= 2) {
      const lo = Number(c[0]);
      const la = Number(c[1]);
      if (Number.isFinite(la) && Number.isFinite(lo)) return { lat: la, lng: lo };
    }
  }
  return null;
}

// 🔹 Liste des risques (collection MongoDB `risques`) — positions pour la carte
//    Query optionnelle: lat, lng, radius (mètres) pour ne retourner que les risques à proximité.
app.get("/risques", async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({
      success: false,
      message: "Service temporairement indisponible.",
      risques: [],
    });
  }
  try {
    const limitRaw = Number(req.query.limit);
    const limit = Number.isFinite(limitRaw)
      ? Math.max(1, Math.min(2000, Math.trunc(limitRaw)))
      : 500;
    const qLat = Number(req.query.lat);
    const qLng = Number(req.query.lng);
    const radiusRaw = Number(req.query.radius);
    const radiusM = Number.isFinite(radiusRaw)
      ? Math.max(100, Math.min(500000, Math.trunc(radiusRaw)))
      : 8000;

    const fetchLimit =
      Number.isFinite(qLat) && Number.isFinite(qLng)
        ? Math.max(limit, 2000)
        : limit;
    const docs = await RisqueModel.find({}).limit(fetchLimit).lean();

    let out = docs;
    if (Number.isFinite(qLat) && Number.isFinite(qLng)) {
      out = docs.filter((d) => {
        const c = extractRisqueCoords(d);
        if (!c) return false;
        return haversineMeters(qLat, qLng, c.lat, c.lng) <= radiusM;
      });
    }

    return res.json({
      success: true,
      risques: out,
    });
  } catch (err) {
    console.error("Erreur GET /risques:", err);
    return res.status(500).json({
      success: false,
      message: "Erreur lors de la lecture des risques.",
      risques: [],
    });
  }
});

// 🔹 Collection problèmes de voirie (optionnel : minLat, maxLat, minLng, maxLng pour filtre bbox)
app.get("/api/problemes-voirie", async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({ success: false, message: "Service indisponible" });
  }
  try {
    const minLat = Number(req.query.minLat);
    const maxLat = Number(req.query.maxLat);
    const minLng = Number(req.query.minLng);
    const maxLng = Number(req.query.maxLng);
    const all =
      req.query.all === "1" ||
      req.query.all === "true" ||
      (typeof req.query.all === "string" &&
        req.query.all.toLowerCase() === "yes");
    const limitRaw = Number(req.query.limit);
    const maxLimit = all ? 10000 : 500;
    const defaultLimit = all ? 5000 : 200;
    const limit = Number.isFinite(limitRaw)
      ? Math.max(1, Math.min(maxLimit, Math.trunc(limitRaw)))
      : defaultLimit;

    const skipRaw = Number(req.query.skip);
    const skip = Number.isFinite(skipRaw) ? Math.max(0, Math.trunc(skipRaw)) : 0;

    const activeOnly =
      req.query.activeOnly === "1" ||
      req.query.activeOnly === "true" ||
      (typeof req.query.activeOnly === "string" &&
        req.query.activeOnly.toLowerCase() === "yes");

    let query = {};
    if (
      Number.isFinite(minLat) &&
      Number.isFinite(maxLat) &&
      Number.isFinite(minLng) &&
      Number.isFinite(maxLng) &&
      minLat < maxLat &&
      minLng < maxLng
    ) {
      query = {
        location: {
          $geoWithin: {
            $geometry: {
              type: "Polygon",
              coordinates: [
                [
                  [minLng, minLat],
                  [maxLng, minLat],
                  [maxLng, maxLat],
                  [minLng, maxLat],
                  [minLng, minLat],
                ],
              ],
            },
          },
        },
      };
    }

    if (activeOnly) {
      const statusClause = {
        $or: [
          { status: { $regex: /^en cours$/i } },
          { status: { $regex: /^en attente$/i } },
          { statut: { $regex: /^en cours$/i } },
          { statut: { $regex: /^en attente$/i } },
        ],
      };
      query = mergeMongoQuery(query, statusClause);
    }

    query = mergeMongoQuery(query, notTerminatedVoirieStatusClause());

    const total = await ProblemeVoirieModel.countDocuments(query);
    const docs = await ProblemeVoirieModel.find(query)
      .sort({ date_detection: -1 })
      .skip(skip)
      .limit(limit)
      .lean();
    const problemes = docs.map(serializeProblemeVoirieDoc);
    return res.json({
      success: true,
      collection: "problemes_de_voirie",
      count: problemes.length,
      total,
      skip,
      limit,
      problemes,
    });
  } catch (err) {
    console.error("Erreur GET /api/problemes-voirie:", err);
    return res.status(500).json({ success: false, message: err.message });
  }
});

// 🔹 API embouteillages
app.get("/api/embouteillages", async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({ success: false, message: "Service indisponible." });
  }
  try {
    const { lat, lng, radius, limit = 100, level, isActive = "true" } = req.query;
    let query = { isActive: isActive === "true" };
    if (level) query.level = level;

    let jams;
    if (lat && lng) {
      const maxDistance = parseInt(radius, 10) || 5000;
      jams = await EmbouteillageModel.findNearby(
        parseFloat(lat),
        parseFloat(lng),
        maxDistance
      ).limit(parseInt(limit, 10));
    } else {
      jams = await EmbouteillageModel.find(query)
        .sort({ detectedAt: -1 })
        .limit(parseInt(limit, 10));
    }
    return res.json({ success: true, count: jams.length, embouteillages: jams });
  } catch (error) {
    console.error("Erreur GET /api/embouteillages:", error);
    return res.status(500).json({ success: false, message: error.message });
  }
});

const EMBOUTEILLAGE_CAUSES = [
  "accident",
  "construction",
  "event",
  "peak_hour",
  "weather",
  "unknown",
];

app.post("/api/embouteillages", optionalAuthMiddleware, async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({ success: false, message: "Service indisponible." });
  }
  try {
    const {
      latitude,
      longitude,
      congestionLevel,
      averageSpeed,
      cause,
      description,
      radius,
      affectedRoads,
    } = req.body;

    if (latitude == null || longitude == null) {
      return res.status(400).json({
        success: false,
        message: "Latitude et longitude requises",
      });
    }

    let causeNorm = typeof cause === "string" ? cause.trim() : "";
    if (!EMBOUTEILLAGE_CAUSES.includes(causeNorm)) causeNorm = "unknown";

    const { doc: jam, merged } = await EmbouteillageModel.updateOrCreate({
      latitude: parseFloat(latitude),
      longitude: parseFloat(longitude),
      congestionLevel: congestionLevel != null ? parseInt(congestionLevel, 10) : 50,
      averageSpeed: averageSpeed != null ? parseFloat(averageSpeed) : 0,
      cause: causeNorm,
      description: description || "",
      radius: radius || 100,
      affectedRoads: Array.isArray(affectedRoads) ? affectedRoads : [],
      source: "user_report",
      reportedBy: req.user && req.user.id ? String(req.user.id) : null,
    });

    if (process.env.LOG_EMBOUTEILLAGES !== "0") {
      const action = merged ? "fusion" : "creation";
      console.log(
        `[embouteillages] ${new Date().toISOString()} POST /api/embouteillages OK (${action}) id=${jam._id} ` +
          `pos=${jam.latitude},${jam.longitude} level=${jam.level} (${jam.congestionLevel}%) ` +
          `cause=${jam.cause} reportCount=${jam.reportCount}`
      );
    }

    const reportedBy = req.user && req.user.id ? String(req.user.id) : null;
    await safeRecordProblemeSignale({
      type: "embouteillage",
      latitude: jam.latitude,
      longitude: jam.longitude,
      userId: reportedBy,
      source: "api_embouteillages",
      meta: {
        embouteillageId: String(jam._id),
        merged: !!merged,
        congestionLevel: jam.congestionLevel,
        level: jam.level,
        cause: jam.cause,
      },
    });

    return res.status(201).json({
      success: true,
      message: "Embouteillage signalé avec succès",
      embouteillage: jam,
      merged: merged,
    });
  } catch (error) {
    console.error("Erreur POST /api/embouteillages:", error);
    return res.status(500).json({ success: false, message: error.message });
  }
});

// 🔹 Signalements citoyens unifiés (collection MongoDB `problemes_signales`)
app.post("/api/problemes-signales", optionalAuthMiddleware, async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({ success: false, message: "Service indisponible." });
  }
  try {
    const typeRaw = typeof req.body.type === "string" ? req.body.type.trim() : "";
    const type = typeRaw;
    const latitude = Number(req.body.latitude);
    const longitude = Number(req.body.longitude);

    if (!type || !PROBLEME_SIGNALE_TYPE_SET.has(type)) {
      return res.status(400).json({ success: false, message: "Type de signalement invalide." });
    }
    if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
      return res.status(400).json({ success: false, message: "Coordonnees invalides." });
    }

    const userId =
      req.user && req.user.id != null
        ? String(req.user.id)
        : req.body.userId != null
          ? String(req.body.userId)
          : null;

    let meta = {};
    if (
      req.body.meta != null &&
      typeof req.body.meta === "object" &&
      !Array.isArray(req.body.meta)
    ) {
      meta = { ...req.body.meta };
    }

    const doc = await ProblemeSignaleModel.create({
      type,
      latitude,
      longitude,
      position: { type: "Point", coordinates: [longitude, latitude] },
      userId,
      source: "api_problemes_signales",
      meta,
    });

    return res.status(201).json({
      success: true,
      message: "Signalement enregistre",
      id: doc._id.toString(),
    });
  } catch (error) {
    console.error("Erreur POST /api/problemes-signales:", error);
    return res.status(500).json({ success: false, message: error.message || "Erreur serveur" });
  }
});

// 🔹 Liste des signalements citoyens (bbox + fenêtre temporelle)
app.get("/api/problemes-signales", async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({ success: false, message: "Service indisponible.", problemes: [] });
  }
  try {
    const minLat = Number(req.query.minLat);
    const maxLat = Number(req.query.maxLat);
    const minLng = Number(req.query.minLng);
    const maxLng = Number(req.query.maxLng);
    const allRaw = req.query.all;
    const fetchAll =
      allRaw === "1" ||
      allRaw === "true" ||
      (typeof allRaw === "string" && allRaw.toLowerCase() === "yes");
    const limitRaw = Number(req.query.limit);
    const limitMax = fetchAll ? 5000 : 500;
    const limit = Number.isFinite(limitRaw)
      ? Math.max(1, Math.min(limitMax, Math.trunc(limitRaw)))
      : fetchAll
        ? Math.min(2000, limitMax)
        : 300;
    const sinceDaysRaw = Number(req.query.sinceDays);
    const sinceDays = Number.isFinite(sinceDaysRaw)
      ? Math.min(90, Math.max(1, Math.trunc(sinceDaysRaw)))
      : 21;
    const cutoff = new Date(Date.now() - sinceDays * 86400000);

    const query = fetchAll ? {} : { createdAt: { $gte: cutoff } };
    if (
      Number.isFinite(minLat) &&
      Number.isFinite(maxLat) &&
      Number.isFinite(minLng) &&
      Number.isFinite(maxLng) &&
      minLat < maxLat &&
      minLng < maxLng
    ) {
      query.latitude = { $gte: minLat, $lte: maxLat };
      query.longitude = { $gte: minLng, $lte: maxLng };
    }

    const docs = await ProblemeSignaleModel.find(query)
      .sort({ createdAt: -1 })
      .limit(limit)
      .lean();
    return res.json({
      success: true,
      count: docs.length,
      problemes: docs,
    });
  } catch (err) {
    console.error("Erreur GET /api/problemes-signales:", err);
    return res.status(500).json({ success: false, message: err.message, problemes: [] });
  }
});

/**
 * Itinéraire → corridor (buffer Turf.js) → problèmes dans la zone (MongoDB $geoWithin + index 2dsphere).
 * Body JSON : { route: [[lng,lat], ...], bufferMeters?, sinceDays?, details?, limitSignales?, limitVoirie? }
 */
app.post("/api/route-corridor-problems", async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({ success: false, message: "Service indisponible." });
  }
  try {
    const rawRoute = req.body.route || req.body.coordinates;
    if (!Array.isArray(rawRoute) || rawRoute.length < 2) {
      return res.status(400).json({
        success: false,
        message: "route invalide (tableau de [lng,lat], minimum 2 points).",
      });
    }
    const coords = [];
    for (const pair of rawRoute) {
      if (!Array.isArray(pair) || pair.length < 2) continue;
      const lng = Number(pair[0]);
      const lat = Number(pair[1]);
      if (!Number.isFinite(lng) || !Number.isFinite(lat)) continue;
      coords.push([lng, lat]);
    }
    if (coords.length < 2) {
      return res.status(400).json({ success: false, message: "coordonnees invalides." });
    }

    const bufferMetersRaw = Number(req.body.bufferMeters);
    const bufferMeters = Number.isFinite(bufferMetersRaw)
      ? Math.min(200, Math.max(40, bufferMetersRaw))
      : 75;

    const sinceDaysRaw = Number(req.body.sinceDays);
    const sinceDays = Number.isFinite(sinceDaysRaw)
      ? Math.min(90, Math.max(1, Math.trunc(sinceDaysRaw)))
      : 21;

    const details = req.body.details !== false && req.body.details !== "false";

    const limitSRaw = Number(req.body.limitSignales);
    const limitVRaw = Number(req.body.limitVoirie);
    const limitSignales = Number.isFinite(limitSRaw)
      ? Math.max(1, Math.min(500, Math.trunc(limitSRaw)))
      : 500;
    const limitVoirie = Number.isFinite(limitVRaw)
      ? Math.max(1, Math.min(500, Math.trunc(limitVRaw)))
      : 500;

    const geometry = buildBufferedGeometryFromRouteLngLat(coords, bufferMeters);
    const cutoff = new Date(Date.now() - sinceDays * 86400000);

    const signaleQuery = {
      position: { $geoWithin: { $geometry: geometry } },
      createdAt: { $gte: cutoff },
    };
    const voirieQuery = mergeMongoQuery(
      {
        location: { $geoWithin: { $geometry: geometry } },
      },
      notTerminatedVoirieStatusClause()
    );

    const [signaleDocs, voirieDocs] = await Promise.all([
      ProblemeSignaleModel.find(signaleQuery)
        .sort({ createdAt: -1 })
        .limit(limitSignales)
        .lean(),
      ProblemeVoirieModel.find(voirieQuery)
        .sort({ date_detection: -1 })
        .limit(limitVoirie)
        .lean(),
    ]);

    const signalesNorm = signaleDocs.map(normalizeSignaleDocForClient);
    const payload = {
      success: true,
      bufferMeters,
      sinceDays,
      counts: {
        signales: signaleDocs.length,
        voirie: voirieDocs.length,
        total: signaleDocs.length + voirieDocs.length,
      },
    };
    if (details) {
      payload.signales = signalesNorm;
      payload.voirie = voirieDocs;
    }
    return res.json(payload);
  } catch (e) {
    console.error("Erreur POST /api/route-corridor-problems:", e);
    return res.status(500).json({
      success: false,
      message: e.message || "Erreur serveur",
    });
  }
});

// 🔹 API accidents
app.post("/api/accidents/report", optionalAuthMiddleware, async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({ success: false, message: "Service indisponible." });
  }
  try {
    const latitude = Number(req.body.latitude);
    const longitude = Number(req.body.longitude);
    const userIdRaw = req.body.userId ?? (req.user && req.user.id ? String(req.user.id) : "anonymous");
    const userId = String(userIdRaw || "anonymous");

    if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
      return res.status(400).json({ success: false, message: "Coordonnees invalides." });
    }

    const now = new Date();
    const fallbackCutoff = new Date(now.getTime() - ACCIDENT_EXPIRY_MS);
    const proximityDelta = 0.0005; // ~50m (approximation)

    const existing = await AccidentModel.findOne({
      "location.lat": { $gte: latitude - proximityDelta, $lte: latitude + proximityDelta },
      "location.lng": { $gte: longitude - proximityDelta, $lte: longitude + proximityDelta },
      $or: [
        { expiresAt: { $gt: now } },
        { expiresAt: null, createdAt: { $gte: fallbackCutoff } },
      ],
    }).sort({ reportCount: -1, createdAt: -1 });

    if (existing) {
      const alreadyReported = existing.userIds.includes(userId);
      if (!alreadyReported) {
        existing.userIds.push(userId);
        existing.reportCount += 1;
      }
      existing.confirmed = existing.reportCount >= 3;
      existing.expiresAt = new Date(Date.now() + ACCIDENT_EXPIRY_MS);
      await existing.save();

      await safeRecordProblemeSignale({
        type: "accident",
        latitude,
        longitude,
        userId,
        source: "api_accidents_report",
        meta: {
          accidentId: String(existing._id),
          reportCount: existing.reportCount,
          confirmed: existing.confirmed,
          merged: true,
        },
      });

      return res.status(200).json({
        success: true,
        message: "Accident existant mis a jour",
        reportCount: existing.reportCount,
        confirmed: existing.confirmed,
        merged: true,
        accident: {
          id: existing._id.toString(),
          location: existing.location,
          createdAt: existing.createdAt,
          expiresAt: existing.expiresAt,
        },
      });
    }

    const accident = new AccidentModel({
      location: { lat: latitude, lng: longitude },
      userIds: [userId],
      reportCount: 1,
      confirmed: false,
      expiresAt: new Date(Date.now() + ACCIDENT_EXPIRY_MS),
    });
    await accident.save();

    await safeRecordProblemeSignale({
      type: "accident",
      latitude,
      longitude,
      userId,
      source: "api_accidents_report",
      meta: {
        accidentId: String(accident._id),
        reportCount: 1,
        confirmed: false,
        merged: false,
      },
    });

    return res.status(201).json({
      success: true,
      message: "Accident signale et enregistre en base",
      reportCount: 1,
      confirmed: false,
      merged: false,
      accident: {
        id: accident._id.toString(),
        location: accident.location,
        createdAt: accident.createdAt,
        expiresAt: accident.expiresAt,
      },
    });
  } catch (error) {
    console.error("Erreur POST /api/accidents/report:", error);
    return res.status(500).json({ success: false, message: "Erreur serveur" });
  }
});

app.get("/api/accidents", async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({ success: false, message: "Service indisponible.", accidents: [] });
  }
  try {
    const { lat, lng } = req.query;
    const now = new Date();
    const fallbackCutoff = new Date(now.getTime() - ACCIDENT_EXPIRY_MS);
    const query = {
      $or: [
        { expiresAt: { $gt: now } },
        { expiresAt: null, createdAt: { $gte: fallbackCutoff } },
      ],
    };

    if (lat != null && lng != null) {
      const latNum = Number(lat);
      const lngNum = Number(lng);
      if (Number.isFinite(latNum) && Number.isFinite(lngNum)) {
        query["location.lat"] = { $gte: latNum - 0.1, $lte: latNum + 0.1 };
        query["location.lng"] = { $gte: lngNum - 0.1, $lte: lngNum + 0.1 };
      }
    }

    const accidents = await AccidentModel.find(query)
      .sort({ reportCount: -1, createdAt: -1 })
      .lean();
    return res.json({ success: true, count: accidents.length, accidents });
  } catch (error) {
    console.error("Erreur GET /api/accidents:", error);
    return res.status(500).json({ success: false, message: "Erreur serveur", accidents: [] });
  }
});

app.get("/api/embouteillages/stats/summary", async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({ success: false, message: "Service indisponible." });
  }
  try {
    const stats = await EmbouteillageModel.aggregate([
      { $match: { isActive: true } },
      {
        $group: {
          _id: "$level",
          count: { $sum: 1 },
          avgCongestion: { $avg: "$congestionLevel" },
        },
      },
    ]);
    const total = await EmbouteillageModel.countDocuments({
      isActive: true,
    });

    return res.json({ success: true, total, statistics: stats });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

app.post("/api/test-embouteillage", async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({ success: false, message: "Service indisponible." });
  }
  try {
    const { doc: testJam } = await EmbouteillageModel.updateOrCreate({
      latitude: 36.8065,
      longitude: 10.1815,
      congestionLevel: 85,
      averageSpeed: 5,
      cause: "accident",
      description: "Accident sur l'autoroute A1",
      affectedRoads: ["A1 Tunis - Bizerte"],
      source: "user_report",
      reportedBy: null,
    });
    return res.json({ success: true, embouteillage: testJam });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

// 🔹 Flux SSE : nouvelle alerte dès insertion MongoDB (rafraîchissement instantané côté app)
app.get("/alert/stream", authMiddleware, (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).send("Service temporairement indisponible.");
  }
  res.setHeader("Content-Type", "text/event-stream; charset=utf-8");
  res.setHeader("Cache-Control", "no-cache, no-transform");
  res.setHeader("Connection", "keep-alive");
  res.setHeader("X-Accel-Buffering", "no");
  if (typeof res.flushHeaders === "function") {
    res.flushHeaders();
  }

  const ping = setInterval(() => {
    try {
      if (!res.writableEnded) res.write(`: ping ${Date.now()}\n\n`);
    } catch (_) {
      clearInterval(ping);
      alertSseClients.delete(res);
    }
  }, 28000);

  alertSseClients.add(res);
  res.write(`data: ${JSON.stringify({ event: "connected" })}\n\n`);

  req.on("close", () => {
    clearInterval(ping);
    alertSseClients.delete(res);
  });
});

// 🔹 Enregistrer le jeton FCM de l’utilisateur connecté (MongoDB `user_citoyen.fcmToken`)
app.put("/user/fcm-token", authMiddleware, async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({
      success: false,
      message: "Service temporairement indisponible.",
    });
  }
  try {
    const { fcmToken } = req.body;
    if (!fcmToken || typeof fcmToken !== "string" || fcmToken.trim().length < 20) {
      return res.status(400).json({
        success: false,
        message: "fcmToken invalide",
      });
    }
    const userId =
      req.user && req.user.id != null ? String(req.user.id) : "";
    if (!userId || !mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(401).json({
        success: false,
        message: "Utilisateur invalide",
      });
    }
    await User.findByIdAndUpdate(userId, { fcmToken: fcmToken.trim() });
    return res.json({ success: true });
  } catch (err) {
    console.error("Erreur PUT /user/fcm-token:", err);
    return res.status(500).json({
      success: false,
      message: "Erreur serveur",
    });
  }
});

// 🔹 Route POST inscription (avec hachage bcrypt)
app.post("/addUser", async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({ 
      message: "Service temporairement indisponible. Connexion à la base de données en cours..." 
    });
  }

  try {
    const { fullName, email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: "Email et mot de passe obligatoires" });
    }

    const existingUser = await User.findOne({ email: email.trim() });
    if (existingUser) {
      return res.status(409).json({ message: "Cet email est déjà utilisé" });
    }

    // 🔥 Hachage du mot de passe
    const hashedPassword = await bcrypt.hash(password, 10);

    const newUser = new User({
      fullName,
      email: email.trim(),
      password: hashedPassword,
    });

    await newUser.save();

    const token = generateToken(newUser._id);
    res.status(201).json({ 
      message: "Utilisateur créé avec succès",
      token,
      user: {
        id: newUser._id.toString(),
        fullName: newUser.fullName,
        email: newUser.email,
      }
    });
  } catch (err) {
    console.error("Erreur lors de la création de l'utilisateur:", err);
    res.status(500).json({ message: "Erreur lors de la création de l'utilisateur" });
  }
});

// 🔹 Route GET vérification email
app.get("/check-email", async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({ exists: false });
  }
  try {
    const email = req.query.email;
    if (!email) return res.status(400).json({ exists: false });
    const user = await User.findOne({ email: email.trim() });
    return res.json({ exists: !!user });
  } catch (err) {
    console.error("Erreur check-email:", err);
    return res.status(500).json({ exists: false });
  }
});

// 🔹 Route POST connexion (avec bcrypt.compare)
app.post("/login", async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({
      success: false,
      message: "Service temporairement indisponible.",
    });
  }
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: "Email et mot de passe obligatoires",
      });
    }

    const user = await User.findOne({ email: email.trim() });
    
    if (!user) {
      return res.status(401).json({
        success: false,
        message: "Email ou mot de passe incorrect",
      });
    }

    // 🔐 Comparaison du mot de passe (haché ou texte brut)
    let isMatch = false;
    try {
      // Si le mot de passe est haché, bcrypt.compare renverra true/false
      isMatch = await bcrypt.compare(password, user.password);
    } catch (err) {
      // Si bcrypt échoue (ex: format invalide), on ignore l'erreur
      isMatch = false;
    }
    
    // Fallback : comparaison texte brut (pour les anciens comptes)
    const isPlainMatch = (user.password === password);
    
    if (!isMatch && !isPlainMatch) {
      return res.status(401).json({
        success: false,
        message: "Email ou mot de passe incorrect",
      });
    }
    
    const token = generateToken(user._id);
    
    return res.json({
      success: true,
      token,
      user: {
        id: user._id.toString(),
        _id: user._id.toString(),
        fullName: user.fullName,
        email: user.email,
        phone: user.phone || null,
        location: user.location || null,
        profileImage: user.profileImage || null,
        createdAt: user.createdAt ? user.createdAt.toISOString() : null,
        dateOfBirth: user.dateOfBirth ? user.dateOfBirth.toISOString() : null,
        gender: user.gender || null,
        cityRegion: user.cityRegion || null,
        safetyScore: user.safetyScore != null ? user.safetyScore : null,
        tripsCount: user.tripsCount != null ? user.tripsCount : 0,
      },
    });
  } catch (err) {
    console.error("Erreur login:", err);
    return res.status(500).json({
      success: false,
      message: "Erreur lors de la connexion",
    });
  }
});

// 🔹 Routes d'authentification sociale
const handleSocialLogin = async (req, res, provider) => {
  if (!isMongoConnected) {
    return res.status(503).json({ error: "Service temporairement indisponible." });
  }

  try {
    const { email, name, providerId, photoUrl } = req.body;

    if (!email || !providerId) {
      return res.status(400).json({ error: "Email et providerId sont obligatoires." });
    }

    let user = await User.findOne({ email });

    if (!user) {
      user = new User({
        fullName: name || email.split('@')[0] || `${provider}_user`,
        email: email.trim(),
        provider: provider,
        providerId: providerId,
        profileImage: photoUrl || "",
        password: await bcrypt.hash(Math.random().toString(36), 10)
      });
      await user.save();
      console.log(`✅ Nouvel utilisateur créé via ${provider}: ${email}`);
    } else {
      user.provider = provider;
      user.providerId = providerId;
      user.lastLogin = new Date();
      if (photoUrl && !user.profileImage) user.profileImage = photoUrl;
      await user.save();
      console.log(`✅ Utilisateur existant connecté via ${provider}: ${email}`);
    }

    const token = generateToken(user._id);

    res.json({
      success: true,
      token,
      user: {
        id: user._id.toString(),
        _id: user._id.toString(),
        fullName: user.fullName,
        email: user.email,
        profileImage: user.profileImage || null,
        provider: user.provider,
        phone: user.phone || null,
        location: user.location || null,
      }
    });
  } catch (error) {
    console.error(`❌ ${provider} login error:`, error);
    res.status(500).json({ error: "Erreur serveur lors de l'authentification sociale." });
  }
};

app.post('/api/auth/google', async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({ error: "Service temporairement indisponible." });
  }

  try {
    const { idToken } = req.body;
    if (!idToken) {
      return res.status(400).json({ error: "idToken est obligatoire." });
    }

    // 🔥 Vérifier token Google
    const payload = await verifyGoogleToken(idToken);
    const { email, name, picture } = payload;

    if (!email) {
      return res.status(400).json({ error: "Email non récupéré depuis Google." });
    }

    let user = await User.findOne({ email: email.trim() });

    if (!user) {
      // ✅ Créer utilisateur
      user = new User({
        fullName: name || email.split('@')[0],
        email: email.trim(),
        provider: "google",
        providerId: payload.sub, // 'sub' est l'ID unique Google
        profileImage: picture || "",
        password: await bcrypt.hash(Math.random().toString(36), 10)
      });
      await user.save();
      console.log(`✅ Nouvel utilisateur créé via Google: ${email}`);
    } else {
      // ✅ Mettre à jour utilisateur existant
      user.provider = "google";
      user.providerId = payload.sub;
      user.lastLogin = new Date();
      if (picture && !user.profileImage) user.profileImage = picture;
      await user.save();
      console.log(`✅ Utilisateur connecté via Google: ${email}`);
    }

    const token = generateToken(user._id);

    res.json({
      success: true,
      token,
      user: {
        id: user._id.toString(),
        _id: user._id.toString(),
        fullName: user.fullName,
        email: user.email,
        profileImage: user.profileImage || null,
        provider: user.provider,
        phone: user.phone || null,
        location: user.location || null,
      }
    });
  } catch (error) {
    console.error("❌ Google login error:", error);
    res.status(401).json({ error: "Token Google invalide ou expiré." });
  }
});

app.post('/api/auth/facebook', (req, res) => handleSocialLogin(req, res, 'facebook'));
app.post('/api/auth/twitter', (req, res) => handleSocialLogin(req, res, 'twitter'));

// 🔹 Authentification Apple sécurisée
async function verifyAppleToken(identityToken, nonce) {
  try {
    const decodedToken = jwt.decode(identityToken, { complete: true });
    if (!decodedToken) throw new Error('Token invalide');

    const { kid, alg } = decodedToken.header;
    const { sub, email, email_verified, nonce: tokenNonce } = decodedToken.payload;

    const key = await appleJwksClient.getSigningKey(kid);
    const publicKey = key.getPublicKey();

    const verified = jwt.verify(identityToken, publicKey, {
      algorithms: [alg],
      audience: 'com.trigressalama.app',
      issuer: 'https://appleid.apple.com',
    });

    if (nonce && tokenNonce !== nonce) {
      throw new Error('Nonce invalide');
    }

    return { valid: true, userId: sub, email: email || null, emailVerified: email_verified || false };
  } catch (error) {
    console.error('Apple token verification failed:', error);
    return { valid: false, error: error.message };
  }
}

app.post('/api/auth/apple', async (req, res) => {
  if (!isMongoConnected) return res.status(503).json({ error: "Service indisponible." });

  try {
    const { identityToken, email, name, nonce } = req.body;
    if (!identityToken) return res.status(400).json({ error: 'Identity token manquant' });

    const verification = await verifyAppleToken(identityToken, nonce);
    if (!verification.valid) return res.status(401).json({ error: 'Token Apple invalide: ' + verification.error });

    let user = await User.findOne({ 
      $or: [
        { providerId: `apple_${verification.userId}` },
        { email: email || verification.email }
      ]
    });

    if (!user) {
      user = new User({
        fullName: name || 'Utilisateur Apple',
        email: email || verification.email || `${verification.userId}@privaterelay.appleid.com`,
        providerId: `apple_${verification.userId}`,
        provider: 'apple',
        password: await bcrypt.hash(crypto.randomBytes(16).toString('hex'), 10)
      });
      await user.save();
      console.log(`✅ Nouvel utilisateur créé via Apple: ${user.email}`);
    } else {
      user.provider = 'apple';
      user.providerId = `apple_${verification.userId}`;
      user.lastLogin = new Date();
      await user.save();
      console.log(`✅ Utilisateur connecté via Apple: ${user.email}`);
    }

    const token = generateToken(user._id);
    res.json({
      success: true,
      token,
      user: {
        id: user._id.toString(),
        fullName: user.fullName,
        email: user.email,
        provider: user.provider
      }
    });
  } catch (error) {
    console.error('❌ Apple auth error:', error);
    res.status(500).json({ error: 'Erreur lors de l\'authentification Apple' });
  }
});

// 🔹 Route PUT mise à jour du profil (PROTÉGÉE)
app.put("/updateProfile", authMiddleware, async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({
      success: false,
      message: "Service temporairement indisponible.",
    });
  }
  try {
    const { userId, fullName, email, phone, location, profileImage, dateOfBirth, gender, cityRegion } = req.body;
    if (!userId && !email) {
      return res.status(400).json({
        success: false,
        message: "userId ou email obligatoire",
      });
    }
    let user = null;
    if (userId && mongoose.Types.ObjectId.isValid(userId) && String(userId).length === 24) {
      user = await User.findById(userId);
    }
    if (!user && email) {
      user = await User.findOne({ email: String(email).trim() });
    }
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "Utilisateur non trouvé",
      });
    }
    if (fullName !== undefined) user.fullName = fullName;
    if (email !== undefined) user.email = String(email).trim();
    if (phone !== undefined) user.phone = phone;
    if (location !== undefined) user.location = location;
    if (profileImage !== undefined) user.profileImage = profileImage;
    if (dateOfBirth !== undefined) user.dateOfBirth = dateOfBirth ? new Date(dateOfBirth) : null;
    if (gender !== undefined) user.gender = gender;
    if (cityRegion !== undefined) user.cityRegion = cityRegion;
    await user.save();
    return res.json({
      success: true,
      user: {
        id: user._id.toString(),
        fullName: user.fullName,
        email: user.email,
        phone: user.phone || null,
        location: user.location || null,
        profileImage: user.profileImage || null,
        createdAt: user.createdAt ? user.createdAt.toISOString() : null,
        dateOfBirth: user.dateOfBirth ? user.dateOfBirth.toISOString() : null,
        gender: user.gender || null,
        cityRegion: user.cityRegion || null,
        safetyScore: user.safetyScore != null ? user.safetyScore : null,
        tripsCount: user.tripsCount != null ? user.tripsCount : 0,
      },
    });
  } catch (err) {
    console.error("Erreur updateProfile:", err);
    return res.status(500).json({
      success: false,
      message: "Erreur lors de la mise à jour du profil",
    });
  }
});

// 🔹 Route POST changer le mot de passe (PROTÉGÉE)
app.post("/changePassword", authMiddleware, async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({
      success: false,
      message: "Service temporairement indisponible.",
    });
  }
  try {
    const { userId, email, currentPassword, newPassword } = req.body;
    if (!newPassword || String(newPassword).trim().length < 6) {
      return res.status(400).json({
        success: false,
        message: "Le nouveau mot de passe doit contenir au moins 6 caractères.",
      });
    }
    if (!currentPassword) {
      return res.status(400).json({
        success: false,
        message: "Mot de passe actuel obligatoire.",
      });
    }
    let user = null;
    if (userId && mongoose.Types.ObjectId.isValid(userId) && String(userId).length === 24) {
      user = await User.findById(userId);
    }
    if (!user && email) {
      user = await User.findOne({ email: String(email).trim() });
    }
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "Utilisateur non trouvé",
      });
    }
    if (user.password !== currentPassword) {
      return res.status(401).json({
        success: false,
        message: "Mot de passe actuel incorrect",
      });
    }
    user.password = String(newPassword).trim();
    await user.save();
    return res.json({
      success: true,
      message: "Mot de passe modifié avec succès",
    });
  } catch (err) {
    console.error("Erreur changePassword:", err);
    return res.status(500).json({
      success: false,
      message: "Erreur lors du changement de mot de passe",
    });
  }
});

// 🔹 Routes contacts d'urgence (PROTÉGÉES)
app.get("/emergency-contacts", authMiddleware, async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({ success: false, message: "Service indisponible.", contacts: [] });
  }
  try {
    const userId = req.query.userId;
    if (!userId) {
      return res.status(400).json({ success: false, message: "userId requis.", contacts: [] });
    }
    const contacts = await EmergencyContactModel.find({ userId: String(userId) }).sort({ isPrimary: -1, createdAt: 1 });
    return res.json({
      success: true,
      contacts: contacts.map((c) => ({
        id: c._id.toString(),
        name: c.name,
        phone: c.phone,
        relationship: c.relationship,
        email: c.email || "",
        isPrimary: !!c.isPrimary,
      })),
    });
  } catch (err) {
    console.error("Erreur GET emergency-contacts:", err);
    return res.status(500).json({ success: false, contacts: [] });
  }
});

app.post("/emergency-contacts", authMiddleware, async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({ success: false, message: "Service indisponible." });
  }
  try {
    const { userId, name, phone, relationship, email, isPrimary } = req.body;
    if (!userId || !name || !phone || !relationship) {
      return res.status(400).json({ success: false, message: "userId, name, phone, relationship requis." });
    }
    if (isPrimary) {
      await EmergencyContactModel.updateMany({ userId: String(userId) }, { isPrimary: false });
    }
    const contact = new EmergencyContactModel({
      userId: String(userId),
      name: String(name).trim(),
      phone: String(phone).trim(),
      relationship: String(relationship).trim(),
      email: email != null ? String(email).trim() : "",
      isPrimary: !!isPrimary,
    });
    await contact.save();
    return res.status(201).json({
      success: true,
      contact: {
        id: contact._id.toString(),
        name: contact.name,
        phone: contact.phone,
        relationship: contact.relationship,
        email: contact.email || "",
        isPrimary: !!contact.isPrimary,
      },
    });
  } catch (err) {
    console.error("Erreur POST emergency-contacts:", err);
    return res.status(500).json({ success: false });
  }
});

app.put("/emergency-contacts/:id", authMiddleware, async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({ success: false, message: "Service indisponible." });
  }
  try {
    const { id } = req.params;
    const { userId, name, phone, relationship, email, isPrimary } = req.body;
    if (!userId) return res.status(400).json({ success: false, message: "userId requis." });
    if (!mongoose.Types.ObjectId.isValid(id) || id.length !== 24) {
      return res.status(400).json({ success: false, message: "ID contact invalide." });
    }
    const contact = await EmergencyContactModel.findById(id);
    if (!contact || contact.userId !== String(userId)) {
      return res.status(404).json({ success: false, message: "Contact non trouvé." });
    }
    if (isPrimary) {
      await EmergencyContactModel.updateMany({ userId: String(userId), _id: { $ne: id } }, { isPrimary: false });
    }
    if (name !== undefined) contact.name = String(name).trim();
    if (phone !== undefined) contact.phone = String(phone).trim();
    if (relationship !== undefined) contact.relationship = String(relationship).trim();
    if (email !== undefined) contact.email = String(email).trim();
    if (isPrimary !== undefined) contact.isPrimary = !!isPrimary;
    await contact.save();
    return res.json({
      success: true,
      contact: {
        id: contact._id.toString(),
        name: contact.name,
        phone: contact.phone,
        relationship: contact.relationship,
        email: contact.email || "",
        isPrimary: !!contact.isPrimary,
      },
    });
  } catch (err) {
    console.error("Erreur PUT emergency-contacts:", err);
    return res.status(500).json({ success: false });
  }
});

app.delete("/emergency-contacts/:id", authMiddleware, async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({ success: false, message: "Service indisponible." });
  }
  try {
    const { id } = req.params;
    const userId = req.query.userId;
    if (!userId) return res.status(400).json({ success: false, message: "userId requis." });
    if (!mongoose.Types.ObjectId.isValid(id) || id.length !== 24) {
      return res.status(400).json({ success: false, message: "ID contact invalide." });
    }
    const contact = await EmergencyContactModel.findOneAndDelete({ _id: id, userId: String(userId) });
    if (!contact) return res.status(404).json({ success: false, message: "Contact non trouvé." });
    return res.json({ success: true });
  } catch (err) {
    console.error("Erreur DELETE emergency-contacts:", err);
    return res.status(500).json({ success: false });
  }
});

// 🔹 Route POST avis utilisateur (MongoDB, protégée JWT)
app.post("/feedback", authMiddleware, async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({
      success: false,
      message: "Service temporairement indisponible.",
    });
  }
  try {
    const userId = req.user && req.user.id != null ? String(req.user.id) : "";
    if (!userId) {
      return res.status(401).json({ success: false, message: "Utilisateur non identifié." });
    }

    const rating = Number(req.body.rating);
    const comment = req.body.comment != null ? String(req.body.comment).trim() : "";

    if (comment.length > 2000) {
      return res.status(400).json({
        success: false,
        message: "Le commentaire ne peut pas dépasser 2000 caractères.",
      });
    }

    if (!Number.isInteger(rating) || rating < 1 || rating > 5) {
      return res.status(400).json({
        success: false,
        message: "La note doit être un entier entre 1 et 5.",
      });
    }

    const doc = new FeedbackModel({
      userId,
      rating,
      comment,
    });
    await doc.save();

    return res.status(201).json({
      success: true,
      message: "Avis enregistré.",
      feedback: {
        id: doc._id.toString(),
        userId: doc.userId,
        rating: doc.rating,
        comment: doc.comment,
        createdAt: doc.createdAt ? doc.createdAt.toISOString() : new Date().toISOString(),
      },
    });
  } catch (err) {
    console.error("Erreur POST feedback:", err);
    return res.status(500).json({
      success: false,
      message: "Erreur lors de l'enregistrement de l'avis.",
    });
  }
});

// 🔹 Route POST capture caméra (MongoDB, protégée JWT)
app.post("/camera-captures", authMiddleware, async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({
      success: false,
      message: "Service temporairement indisponible.",
    });
  }
  try {
    const userId = req.user && req.user.id != null ? String(req.user.id) : "";
    if (!userId) {
      return res.status(401).json({ success: false, message: "Utilisateur non identifié." });
    }

    const imageBase64 = req.body.imageBase64 != null ? String(req.body.imageBase64).trim() : "";
    const latitude = Number(req.body.latitude);
    const longitude = Number(req.body.longitude);

    if (!imageBase64) {
      return res.status(400).json({ success: false, message: "Image obligatoire." });
    }
    if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
      return res.status(400).json({ success: false, message: "Coordonnées invalides." });
    }
    if (imageBase64.length > 20 * 1024 * 1024) {
      return res.status(400).json({ success: false, message: "Image trop volumineuse." });
    }

    const doc = new CameraCaptureModel({
      userId,
      imageBase64,
      latitude,
      longitude,
    });
    await doc.save();

    return res.status(201).json({
      success: true,
      message: "Capture enregistrée.",
      capture: {
        id: doc._id.toString(),
        userId: doc.userId,
        latitude: doc.latitude,
        longitude: doc.longitude,
        createdAt: doc.createdAt ? doc.createdAt.toISOString() : new Date().toISOString(),
      },
    });
  } catch (err) {
    console.error("Erreur POST camera-captures:", err);
    return res.status(500).json({
      success: false,
      message: "Erreur lors de l'enregistrement de la capture.",
    });
  }
});

// 🔹 Route GET captures caméra de l'utilisateur connecté
app.get("/camera-captures", authMiddleware, async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).json({
      success: false,
      message: "Service temporairement indisponible.",
      captures: [],
    });
  }
  try {
    const userId = req.user && req.user.id != null ? String(req.user.id) : "";
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "Utilisateur non identifié.",
        captures: [],
      });
    }

    const limitRaw = Number(req.query.limit);
    const limit = Number.isFinite(limitRaw) ? Math.max(1, Math.min(200, Math.trunc(limitRaw))) : 50;

    const docs = await CameraCaptureModel
      .find({ userId })
      .sort({ createdAt: -1 })
      .limit(limit);

    return res.json({
      success: true,
      captures: docs.map((doc) => ({
        id: doc._id.toString(),
        userId: doc.userId,
        imageBase64: doc.imageBase64,
        latitude: doc.latitude,
        longitude: doc.longitude,
        createdAt: doc.createdAt ? doc.createdAt.toISOString() : new Date().toISOString(),
      })),
    });
  } catch (err) {
    console.error("Erreur GET camera-captures:", err);
    return res.status(500).json({
      success: false,
      message: "Erreur lors de la lecture des captures.",
      captures: [],
    });
  }
});

// 🔹 Route GET image binaire d'une capture (pour usage URL/Image.network)
app.get("/camera-captures/:id/image", authMiddleware, async (req, res) => {
  if (!isMongoConnected) {
    return res.status(503).send("Service temporairement indisponible.");
  }
  try {
    const userId = req.user && req.user.id != null ? String(req.user.id) : "";
    if (!userId) {
      return res.status(401).send("Utilisateur non identifié.");
    }

    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id) || id.length !== 24) {
      return res.status(400).send("ID capture invalide.");
    }

    const capture = await CameraCaptureModel.findById(id);
    if (!capture) {
      return res.status(404).send("Capture introuvable.");
    }
    if (String(capture.userId) !== userId) {
      return res.status(403).send("Accès interdit.");
    }

    const raw = String(capture.imageBase64 || "").trim();
    if (!raw) {
      return res.status(404).send("Image introuvable.");
    }

    // Supporte:
    // 1) base64 pur
    // 2) data URI: data:image/jpeg;base64,...
    let mime = "image/jpeg";
    let payload = raw;
    const dataPrefixMatch = raw.match(/^data:(image\/[a-zA-Z0-9+.-]+);base64,/);
    if (dataPrefixMatch) {
      mime = dataPrefixMatch[1] || mime;
      payload = raw.split(",").slice(1).join(",");
    }

    let buffer;
    try {
      buffer = Buffer.from(payload, "base64");
    } catch (e) {
      return res.status(400).send("Image base64 invalide.");
    }

    res.set("Content-Type", mime);
    res.set("Cache-Control", "public, max-age=3600");
    return res.send(buffer);
  } catch (err) {
    console.error("Erreur GET /camera-captures/:id/image:", err);
    return res.status(500).send("Erreur serveur.");
  }
});

// 🔹 Lancer serveur
function getLocalIp() {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === "IPv4" && !iface.internal) {
        return iface.address;
      }
    }
  }
  return "127.0.0.1";
}

app.listen(3000, "0.0.0.0", () => {
  const localIp = getLocalIp();
  console.log("\n🚀 Server running on http://0.0.0.0:3000");
  console.log("📱 Emulator  : http://10.0.2.2:3000");
  console.log("📱 Real device: http://" + localIp + ":3000");
  console.log("\n👉 Run app with: flutter run --dart-define=BASE_URL=http://" + localIp + ":3000");
  console.log("⚠️  Make sure device is on the SAME Wi-Fi network!\n");
});