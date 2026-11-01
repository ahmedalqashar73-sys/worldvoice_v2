import test from "node:test";
import assert from "node:assert/strict";
import {canManageGroupMessage} from "../src/group_management_routes.js";

const group = {
  type:"group", active:true, ownerId:"owner",
  memberIds:["owner","mod","alice","bob"], moderatorIds:["mod"],
};
const textMessage = {senderId:"alice",type:"text"};
const voiceMessage = {senderId:"alice",type:"audio"};

test("authors can edit their text and re-record voice but nobody else can", () => {
  assert.equal(canManageGroupMessage(group,textMessage,"alice","edit"),true);
  assert.equal(canManageGroupMessage(group,textMessage,"bob","edit"),false);
  assert.equal(canManageGroupMessage(group,voiceMessage,"alice","replace_audio"),true);
  assert.equal(canManageGroupMessage(group,voiceMessage,"mod","replace_audio"),false);
  assert.equal(canManageGroupMessage(group,textMessage,"alice","replace_audio"),false);
  assert.equal(canManageGroupMessage(group,voiceMessage,"alice","edit"),false);
});
test("authors, group owner and moderators can remove messages", () => {
  for (const user of ["alice","owner","mod"]) {
    assert.equal(canManageGroupMessage(group,textMessage,user,"delete"),true);
  }
  assert.equal(canManageGroupMessage(group,textMessage,"bob","delete"),false);
});
test("removed users, inactive groups and deleted messages cannot be modified", () => {
  assert.equal(canManageGroupMessage(group,textMessage,"outsider","delete"),false);
  assert.equal(canManageGroupMessage({...group,active:false},textMessage,"alice","edit"),false);
  assert.equal(canManageGroupMessage(group,{...textMessage,deleted:true},"alice","delete"),false);
});
