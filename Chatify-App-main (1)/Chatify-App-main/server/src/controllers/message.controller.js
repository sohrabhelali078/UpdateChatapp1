const messageModel = require("../models/message.model");
const chatModel = require("../models/chat.model");
const userModel = require("../models/user.model");
const Group = require("../models/group-chat.model");
const mongoose = require("mongoose");

const messageController = {
  allMessages: async (req, res) => {
    try {
      const messages = await messageModel
        .find({ chat: req.params.chatId })
        .populate("sender", "name image email")
        .populate("chat");
      res.json(messages);
    } catch (error) {
      res.status(400);
      throw new Error(error.message);
    }
  },

  sendMessage: async (req, res) => {
    const { content, chatId, filePath } = req.body;

    if (!content || !chatId) {
      console.log("Invalid data passed into request");
      return res.sendStatus(400);
    }

    const currentUser = await userModel.findById(req.user._id);
    const chat = await chatModel.findById(chatId).populate("users");

    if (currentUser.isBlocked) {
      return res
        .status(403)
        .json({ message: "You are blocked from sending messages." });
    }

    if (
      chat.users.some((user) => user.isBlocked && user._id.equals(req.user._id))
    ) {
      return res
        .status(403)
        .json({ message: "You are blocked from this chat." });
    }

    try {
      const newMessage = {
        sender: req.user._id,
        content: content,
        chat: chatId,
        filePath: filePath || null,
      };

      let message = await messageModel.create(newMessage);

      message = await message.populate("sender", "name image");
      message = await message.populate("chat");
      message = await userModel.populate(message, {
        path: "chat.users",
        select: "name image email",
      });

      await chatModel.findByIdAndUpdate(chatId, { latestMessage: message });

      res.json(message);
    } catch (error) {
      res.status(400);
      throw new Error(error.message);
    }
  },

  readMessage: async (req, res, next) => {
    const messageId = req.params.messageId;

    if (!messageId) {
      console.log("Invalid data passed into request");
      return res.sendStatus(400);
    }

    await messageModel
      .findByIdAndUpdate(messageId, { readBy: req.user._id })
      .then(async (message) => {
        res.json(message);
      })
      .catch(next);
  },

  sendGroupMessages: async (req, res) => {
    const senderId = req.user.email; // Ensure this is a valid ObjectId
    const { groupId, content } = req.body;

    // Validate ObjectId
    if (!mongoose.Types.ObjectId.isValid(groupId)) {
      console.log({ message: "Invalid groupId" });
    }

    // Find the group
    const group = await Group.findById(groupId);

    if (!group) {
      console.log("Group not found:", groupId);
      return res.status(404).json({ message: "Group not found" });
    }

    // Create message object with ObjectId conversion
    const message = {
      sender: senderId,
      content,
    };

    console.log("Message to be added:", message);

    // Add message to group's messages array
    group.messages.push(message);
    const updatedGroup = await group.save();

    res.status(201).json(message);
  },
};

module.exports = messageController;
