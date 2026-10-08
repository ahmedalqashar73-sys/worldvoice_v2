// Compatibility exports for the older wallet migration command and tests.
// The single authoritative allowlists and validation now live in
// profile_projection.js; do not fork those rules in two modules.
export {
  projectPublicProfile as sanitizedPublicProfile,
  extractLegacyWallet as extractPrivateWallet,
} from "./profile_projection.js";
