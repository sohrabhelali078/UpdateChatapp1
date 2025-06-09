const chatRoute = require("./chat.route");
const messageRoute = require("./message.route");
const userRoute = require("./user.route");
const groupChatRouter = require("./group-chat.route");

const routes = (app) => {
  userRoute(app);
  chatRoute(app);
  messageRoute(app);
  groupChatRouter(app);
};

module.exports = routes;
