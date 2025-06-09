const Group = require("../models/group-chat.model");
const User = require("../models/user.model");

exports.createGroup = async (req, res) => {
  const { name, members } = req.body;
  console.log(name, members);
  try {
    const group = new Group({
      name,
      members,
    });

    await group.save();

    res.status(201).json(group);
  } catch (error) {
    res.status(500).json({ message: "Error creating group", error });
  }
};

exports.addMember = async (req, res) => {
  const { groupId, memberId } = req.body;

  try {
    const group = await Group.findById(groupId);
    const user = await User.findById(memberId);

    if (!group || !user) {
      return res.status(404).json({ message: "Group or User not found" });
    }

    group.members.push(memberId);
    await group.save();

    res.status(200).json(group);
  } catch (error) {
    res.status(500).json({ message: "Error adding member", error });
  }
};

exports.removeMember = async (req, res) => {
  const { groupId, memberId } = req.params;
  console.log(groupId);
  console.log(memberId);

  try {
    const group = await Group.findById(groupId);

    if (!group) {
      return res.status(404).json({ message: "Group not found" });
    }

    group.members = group.members.filter(
      (member) => member.toString() !== memberId
    );
    await group.save();

    res.status(200).json(group);
  } catch (error) {
    res.status(500).json({ message: "Error removing member", error });
  }
};

exports.getGroups = async (req, res) => {
  try {
    const groups = await Group.find({});
    res.status(200).json(groups);
  } catch (error) {
    res.status(500).json({ message: "Error fetching groups", error });
  }
};

exports.getOneGroupMessages = async (req, res) => {
  const { groupId } = req.params;

  console.log(groupId);

  try {
    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({ message: "Group not found" });
    }

    res.status(200).json(group.messages);
  } catch (error) {
    res.status(500).json({ message: "Error fetching group messages", error });
  }
};

exports.getOneGroupMembers = async (req, res) => {
  const { groupId } = req.params;

  try {
    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({ message: "Group not found" });
    }

    const members = await User.find({ _id: { $in: group.members } });

    res.status(200).json(members);
  } catch (error) {
    res.status(500).json({ message: "Error fetching group members", error });
  }
};
