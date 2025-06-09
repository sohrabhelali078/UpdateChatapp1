const express = require("express");

const userController = require("../controllers/user.controller");
const { protect } = require("../middlewares/auth.middleware");

const router = express.Router();

const userRoute = (app) => {
  router.post("/register", userController.handleRegister);
  router.post("/reg", (req, res) => {
    return "hi";
  });
  router.post("/login", userController.handleLogin);
  router.put("/update/:id", userController.handleUpdate);
  router.delete("/delete/:id", userController.handleDelete);
  router.get("/", userController.getAllUsers);
  router.get("/get-all-users", userController.getAllUsers2);
  router.post("/block/:id", userController.handleBlockUser);
  router.get(
    "/is-blocked/:userId",
    userController.authenticate,
    userController.checkIfBlocked
  );
  router.post("/unblock/:userId", userController.handleBlockUser);

  return app.use("/api/user", router);
};

module.exports = userRoute;
