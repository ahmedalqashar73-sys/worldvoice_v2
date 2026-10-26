import {createHash} from "node:crypto";

const invalid = (reason, status = 403) =>
  Object.assign(new Error(reason), {status});

export function chatIdFor(uid, peerId) {
  if (typeof uid !== "string" || typeof peerId !== "string" ||
      !/^[A-Za-z0-9_-]{8,160}$/.test(uid) ||
      !/^[A-Za-z0-9_-]{8,160}$/.test(peerId) || uid === peerId) {
    throw invalid("Invalid chat participants.", 400);
  }
  const [one, two] = [uid, peerId].sort();
  return createHash("sha256").update("worldvoice:chat:" + one + ":" + two)
    .digest("hex");
}

export function assertChatMembership(data, senderId, recipientId) {
  if (data?.active !== true || !Array.isArray(data.memberIds) ||
      data.memberIds.length !== 2 ||
      !data.memberIds.includes(senderId) ||
      !data.memberIds.includes(recipientId) ||
      senderId === recipientId ||
      data.memberIds.some(id => typeof id !== "string") ||
      !/^[a-f0-9]{64}$/.test(chatIdFor(senderId, recipientId))) {
    throw invalid("Verified chat membership required.");
  }
  return true;
}
