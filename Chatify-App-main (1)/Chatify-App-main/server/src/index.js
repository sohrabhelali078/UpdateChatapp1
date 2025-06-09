const express = require("express");
const path = require("path");
const routes = require("./routes");
const bodyParser = require("body-parser");
const cors = require("cors");
const multer = require("multer");
const app = express();
const http = require("http");
const server = http.createServer(app);
const { Server } = require("socket.io");
const io = new Server(server);

require("./config/db")();

const host = "192.168.12.1";
const port = 7000;

app.use(bodyParser.json({ limit: "50mb" }));
app.use(
  bodyParser.urlencoded({
    limit: "50mb",
    extended: true,
    parameterLimit: 50000,
  })
);

app.use(cors());

// Multer setup for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, "uploads"));
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname));
  },
});
const upload = multer({ storage });

// Serve static files
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// Routes for file upload
app.post("/upload", upload.single("file"), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ message: "No file uploaded" });
  }

  const fileUrl = `http://${host}:${port}/uploads/${req.file.filename}`; // Update with your file URL

  // Respond with file data including the download link
  res.status(200).json({
    fileName: req.file.originalname,
    url: fileUrl,
    _id: req.file.filename, // Optionally include a unique ID
  });
});

routes(app);

io.on("connection", (socket) => {
  console.log("Connected with socket IO");

  socket.on("join-chat", (room) => {
    socket.join(room);
    console.log(`Socket ${socket.id} joined room ${room}`);
  });

  socket.on("on-chat", (data) => {
    const roomId = data.chatId; // Ensure chatId is correct in data
    io.to(roomId).emit(roomId, data);
    console.log(`Message sent to room ${roomId}: ${data.content}`);
  });

  socket.on("all", (data) => {
    io.emit("all", data);
  });

  socket.on("disconnect", () => {
    console.log("User disconnected");
  });
});

server.listen(port, host, () => {
  console.log(path.join(__dirname, "uploads"));
  console.log(`servers listening at http://${host}:${port})`);
});
