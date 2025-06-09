const userModel = require("../models/user.model");

const jwt = require("jsonwebtoken");

class UserService {
  static async registerUser(userInfo) {
    try {
      const createUser = new userModel(userInfo);
      return await createUser.save();
    } catch (error) {
      throw error;
    }
  }

  static async checkEmail(email) {
    try {
      return await userModel.findOne({ email });
    } catch (error) {
      throw error;
    }
  }

  static async generateToken(tokenData, secretKey, jwtExpire) {
    return jwt.sign(tokenData, secretKey, { expiresIn: jwtExpire });
  }

  static async updateUser(userInfo) {
    const updateUser = await userModel.updateOne(
      { _id: userInfo._id },
      userInfo
    );
    return updateUser;
  }

  static async deleteUser(_id) {
    const user = await userModel.findOneAndDelete({ _id });
    return user;
  }

  static async blockUser(userId) {
    const user = await userModel.findById(userId);
    if (!user) {
      throw new Error("User not found");
    }
    if (user.isBlocked === true) {
      user.isBlocked = false;
    } else {
      user.isBlocked = true;
    }
    // Assuming you have an `isBlocked` field in your user model
    await user.save();
    return user;
  }
}

module.exports = UserService;
