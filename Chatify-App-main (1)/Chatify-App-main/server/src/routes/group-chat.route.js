const express = require("express");
const { protect } = require("../middlewares/auth.middleware");
const {
  createGroup,
  addMember,
  removeMember,
  getGroups,
  getOneGroupMessages,
  getOneGroupMembers,
} = require("../controllers/group-chat.controller");
const messageController = require("../controllers/message.controller");

console.log(createGroup);

const router = express.Router();

const groupChatRouter = (app) => {
  router.post("/create", (req, res) => createGroup(req, res));
  router.post("/add-member", (req, res) => addMember(req, res));
  router.post("/remove-member/:groupId/:memberId", (req, res) =>
    removeMember(req, res)
  );
  router.post("/messages", protect, (req, res) =>
    messageController.sendGroupMessages(req, res)
  );
  router.get("/all", (req, res) => getGroups(req, res));
  router.get("/get-one/:groupId", (req, res) => getOneGroupMessages(req, res));
  router.get("/get-members/:groupId", (req, res) =>
    getOneGroupMembers(req, res)
  );

  return app.use("/api/group-chat", router);
};

module.exports = groupChatRouter;
