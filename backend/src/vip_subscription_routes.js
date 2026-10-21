import {createHash} from "node:crypto";
import {google} from "googleapis";
import {Timestamp, FieldValue} from "firebase-admin/firestore";
import {AppStoreServerAPIClient, Environment, SignedDataVerifier} from
  "@apple/app-store-server-library";
import {googleVipPeriod, appleVipPeriod} from "./vip_subscription_policy.js";

function fail(message, status = 409) {
  return Object.assign(new Error(message), {status});
}

async function verifyAppleSubscription({transactionId, productId, bundleId,
  privateKey, keyId, issuerId}) {
  const rootsJson = process.env.APPLE_ROOT_CERTIFICATES_BASE64_JSON || "";
  const appId = Number(process.env.APPLE_APP_ID || 0);
  if (!privateKey || !keyId || !issuerId || !rootsJson) {
    throw fail("Apple subscription verification is not configured.", 503);
  }
  let certs;
  try {
    certs = JSON.parse(rootsJson).map(value => Buffer.from(value, "base64"));
    if (!Array.isArray(certs) || certs.length === 0 ||
        certs.some(value => value.length < 100)) throw Error("No certificates.");
  } catch {
    throw fail("Apple root certificates are invalid.", 503);
  }

  for (const environment of [Environment.PRODUCTION, Environment.SANDBOX]) {
    if (environment === Environment.PRODUCTION &&
        (!Number.isSafeInteger(appId) || appId <= 0)) continue;
    try {
      const client = new AppStoreServerAPIClient(
        privateKey, keyId, issuerId, bundleId, environment);
      const serverResult = await client.getTransactionInfo(transactionId);
      if (!serverResult.signedTransactionInfo) continue;
      // Never decode a store JWS as trusted JSON without validating its
      // certificate chain and signature.
      const verifier = new SignedDataVerifier(
        certs, true, environment, bundleId,
        environment === Environment.PRODUCTION ? appId : undefined);
      const transaction = await verifier.verifyAndDecodeTransaction(
        serverResult.signedTransactionInfo);
      const period = appleVipPeriod(transaction, productId, bundleId);
      if (period) return period;
    } catch (_) {
      // Try Sandbox after Production. Do not leak provider errors or secrets.
    }
  }
  throw fail("No verified active Apple VIP subscription.");
}

async function verifyGoogleSubscription({token, productId, packageName, auth}) {
  const androidPublisher = google.androidpublisher({version:"v3", auth});
  const reply = await androidPublisher.purchases.subscriptionsv2.get({
    packageName, token,
  });
  const period = googleVipPeriod(reply.data, productId);
  if (!period) throw fail("No verified active Google VIP subscription.");
  // Purchase token is stable across renewals; order IDs are not.
  return {...period, receiptId: token};
}

export function registerVipSubscriptionRoutes({app, db, authenticatedUser,
  googlePlayAuth, androidPackageName, iosBundleId, appleIapKeyId,
  appleIapIssuerId, appleIapPrivateKey}) {
  app.post("/vip/iap/verify", async (req, res, next) => {
    try {
      const account = await authenticatedUser(req);
      if (process.env.VIP_SUBSCRIPTIONS_ENABLED !== "true") {
        throw fail("VIP subscriptions are not enabled for public purchase.", 503);
      }
      const platform = String(req.body?.platform || "").trim();
      const productId = String(req.body?.productId || "").trim();
      const purchaseId = String(req.body?.purchaseId || "").trim();
      const verificationData = String(req.body?.verificationData || "").trim();

      if (!["android", "ios"].includes(platform) ||
          !/^wv_vip_[A-Za-z0-9_.-]{3,148}$/.test(productId) ||
          verificationData.length < 3 || verificationData.length > 12000) {
        return res.status(400).json({error: "Invalid subscription verification data."});
      }
      const vipConfig = await db.doc("vip_config/current").get();
      if (vipConfig.data()?.enabled !== true ||
          vipConfig.data()?.storeIntegrationVerified !== true) {
        throw fail("VIP store setup has not been approved.", 503);
      }
      const skuField = platform === "android"
        ? "androidProductId" : "iosProductId";
      const catalog = await db.collection("vip_products")
        .where(skuField, "==", productId).limit(2).get();
      if (catalog.size !== 1 || catalog.docs[0].data()?.active !== true ||
          catalog.docs[0].data()?.tier !== "gold") {
        return res.status(409).json({error: "This VIP product is not approved."});
      }
      const verified = platform === "android"
        ? await verifyGoogleSubscription({
          token: verificationData, productId,
          packageName: androidPackageName, auth: googlePlayAuth,
        })
        : await verifyAppleSubscription({
          transactionId: purchaseId,
          productId, bundleId: iosBundleId,
          privateKey: appleIapPrivateKey, keyId: appleIapKeyId,
          issuerId: appleIapIssuerId,
        });
      const expiry = verified.expiry;
      if (!Number.isSafeInteger(expiry) || expiry <= Date.now()) {
        throw fail("VIP entitlement is not active.");
      }

      const profileRef = db.collection("users").doc(account.uid);
      const receiptId = createHash("sha256")
        .update(platform + ":" + verified.receiptId).digest("hex");
      const receiptRef = db.collection("vip_purchase_receipts").doc(receiptId);

      await db.runTransaction(async tx => {
        const [profile, receipt] = await Promise.all([
          tx.get(profileRef), tx.get(receiptRef),
        ]);
        if (!profile.exists) throw fail("Complete your WorldVoice profile first.", 404);
        if (receipt.exists && receipt.data()?.uid !== account.uid) {
          throw fail("Subscription is already linked to another account.", 409);
        }
        const previous = profile.data()?.vipExpiresAt?.toMillis?.() || 0;
        const validPrevious = Number.isFinite(previous) ? previous : 0;
        const finalExpiry = Math.max(expiry, validPrevious);
        const admin = profile.data()?.vipSource === "worldvoice_admin_allowlist";

        tx.set(receiptRef, {
          uid: account.uid,
          platform,
          productId,
          catalogId: catalog.docs[0].id,
          expiresAt: Timestamp.fromMillis(expiry),
          updatedAt: FieldValue.serverTimestamp(),
          ...(receipt.exists ? {} : {verifiedAt: FieldValue.serverTimestamp()}),
        }, {merge: true});

        // Do not turn an unexpired admin grant into a shorter paid membership.
        tx.set(profileRef, {
          isVip: true,
          vipTier: "gold",
          vipExpiresAt: Timestamp.fromMillis(finalExpiry),
          ...(admin ? {} : {vipSource: platform + "_subscription"}),
          vipUpdatedAt: FieldValue.serverTimestamp(),
        }, {merge: true});
      });

      return res.json({
        ok: true,
        tier: "gold",
        expiresAt: new Date(expiry).toISOString(),
      });
    } catch (error) {
      next(error);
    }
  });
}
