const userModel = require("../models/user.model");
const UserService = require("../services/user.service");

const userController = {
  handleRegister: async (req, res, next) => {
    await UserService.registerUser(req.body)
      .then(() => {
        res.json({ status: true, success: "User Registered Successfully" });
      })
      .catch(next);
  },

  handleLogin: async (req, res, next) => {
    const { email, password } = req.body;
    await UserService.checkEmail(email)
      .then(async (user) => {
        if (!user) {
          throw new Error(`User don't exist`);
        }

        const isMatch = await user.comparePassword(password);
        if (isMatch === false) {
          throw new Error(`Password invalid`);
        }

        let tokenData = {
          _id: user._id,
          name: user.name,
          email: user.email,
          image: user.image,
        };
        const token = await UserService.generateToken(
          tokenData,
          "secretKey",
          "1d"
        );

        res.status(200).json({ status: true, token });
      })
      .catch(next);
  },

  handleUpdate: async (req, res, next) => {
    const _id = req.params.id;
    console.log(req.body);
    await UserService.updateUser({ _id, ...req.body })
      .then(async (user) => {
        let tokenData = {
          _id: user._id,
          //   name: user.name,
          email: user.email,
          password: user.password,
          //   image: user.image,
        };
        const token = await UserService.generateToken(
          tokenData,
          "secretKey",
          "1d"
        );
        res.status(200).json({ status: true, token });
      })
      .catch(next);
  },

  handleDelete: async (req, res, next) => {
    const _id = req.params.id;
    await UserService.deleteUser(_id)
      .then((user) => {
        res.status(200).json({
          status: true,
          user,
        });
      })
      .catch(next);
  },

  getAllUsers: async (req, res, next) => {
    const keyword = req.query.search
      ? {
          $or: [
            { name: { $regex: req.query.search, $options: "i" } },
            { email: { $regex: req.query.search, $options: "i" } },
          ],
        }
      : {};

    const users = await userModel
      .find(keyword)
      .find({ _id: { $ne: req.user._id } });
    res.send(users);
  },

  getAllUsers2: async (req, res, next) => {
    const keyword = req.query.search
      ? {
          $or: [
            { name: { $regex: req.query.search, $options: "i" } },
            { email: { $regex: req.query.search, $options: "i" } },
          ],
        }
      : {};

    const users = await userModel.find(keyword);
    res.send(users);
  },

  handleBlockUser: async (req, res, next) => {
    const _id = req.params.id;
    await UserService.blockUser(_id)
      .then((user) => {
        res.status(200).json({
          status: true,
          user,
        });
      })
      .catch(next);
  },

  async authenticate(req, res, next) {
    const token = req.headers["authorization"]?.split(" ")[1]; // Extract token from Bearer schema

    if (!token) {
      return res.status(401).send("Access denied");
    }

    try {
      const decoded = jwt.verify(token, "secretKey"); // Verify the token
      req.user = await userModel.findById(decoded._id); // Set req.user with the authenticated user
      if (!req.user) {
        return res.status(404).send("User not found");
      }
      next(); // Proceed to the next middleware/handler
    } catch (error) {
      res.status(401).send("Invalid token"); // Handle invalid token
    }
  },

  checkIfBlocked: async (req, res, next) => {
    const userId = req.params.userId;

    console.log("Received userId:", userId); // Log to verify
    console.log("req.user:", req.user); // Log to verify req.user

    if (!userId) {
      console.log("UserId param not sent with request");
      return res.sendStatus(400);
    }

    if (!req.user) {
      console.log("User not found in request");
      return res.status(401).send("User not authenticated");
    }

    try {
      const user = await userModel.findById(userId).populate("blockedUsers");
      if (!user) {
        throw new Error("User not found");
      }
      if (user.blockedUsers.includes(userId)) {
        return res.status(200).json({ blocked: true });
      } else {
        return res.status(200).json({ blocked: false });
      }
    } catch (error) {
      console.error("Error in checkIfBlocked:", error); // Improved logging
      res.status(400).send(error.message);
    }
  },

  unblockUser: async (req, res) => {
    const { userId } = req.params;

    if (!userId) {
      return res.status(400).send("User ID is required");
    }

    try {
      const user = await userModel.findById(req.user._id);

      if (!user) {
        return res.status(404).send("User not found");
      }

      // Set blocked field to false
      await userModel.findByIdAndUpdate(userId, { blocked: false });

      res
        .status(200)
        .json({ status: true, message: "User unblocked successfully" });
    } catch (error) {
      console.error("Error in unblockUser:", error);
      res.status(400).send(error.message);
    }
  },
};

module.exports = userController;
