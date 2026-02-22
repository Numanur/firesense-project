import express from "express";
import http from "http";
import { Server } from "socket.io";
import os from "os";
import path from "path";

const app = express();

const PORT = process.env.PORT || 3000;

// Create HTTP + Socket.IO server
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: "*" },
});

// Namespaces
const python = io.of("/python");
const appClient = io.of("/app");
const iot = io.of("/iot"); // ✅ ADD THIS

// ====== PYTHON CONNECTION =======
python.on("connection", (socket) => {
  console.log("🐍 Python connected");

  socket.on("frame", (data) => {
    // Extract detection data
    const fire = data.fire_area;
    const smoke = data.smoke_area;
    const alert = data.any_alert;
    const ts = new Date(data.timestamp * 1000).toLocaleString();

    // Pretty console logging
    // console.log("\n====== 🔥 Detection Frame Received ======");
    // console.log(`Timestamp : ${ts}`);
    // console.log(`Fire Area : ${fire}`);
    // console.log(`Smoke Area: ${smoke}`);
    // console.log(
    //   `Alert     : ${alert ? "🔥 YES (Fire/Smoke Detected)" : "✔️ NO"}`
    // );
    // console.log("========================================\n");

    // Forward frame + data to Flutter/browser
    appClient.emit("frame", data);
  });

  socket.on("disconnect", () => {
    console.log("🐍 Python disconnected");
  });
});

// ====== APP/FLUTTER CONNECTION =======
appClient.on("connection", () => {
  console.log("📱 App connected");
});

// Simple home route
app.get("/", (req, res) => {
  res.send("🔥 Fire Detection Server Running");
});

// Serve test page (optional)
app.get("/test", (req, res) => {
  res.sendFile(path.join(__dirname, "public/test.html"));
});

function generateSensorData() {
  const temperature = +(20 + Math.random() * 60).toFixed(1);
  const gas = Math.floor(100 + Math.random() * 400);
  const smoke = Math.floor(50 + Math.random() * 300);
  const flame = Math.random() < 0.15;

  const unsafe = temperature > 60 || gas > 300 || smoke > 150 || flame;

  return {
    temperature,
    gas,
    smoke,
    flame,
    unsafe,
    timestamp: Date.now(),
  };
}

iot.on("connection", (socket) => {
  console.log("📡 Flutter IoT dashboard connected");

  const interval = setInterval(() => {
    const data = generateSensorData();

    socket.emit("sensor_data", data);

    console.log(
      `📊 IoT | Temp:${data.temperature}°C | Gas:${data.gas} | Smoke:${data.smoke} | Flame:${data.flame} | Status:${data.unsafe ? "UNSAFE" : "SAFE"}`,
    );
  }, 5000); // ✅ 5 seconds

  socket.on("disconnect", () => {
    clearInterval(interval);
    console.log("📡 Flutter IoT dashboard disconnected");
  });
});

// ====== START SERVER =======
server.listen(PORT, "0.0.0.0", () => {
  console.log(`\n🚀 Express + Socket.IO listening on port ${PORT}`);

  const nets = os.networkInterfaces();
  for (const name of Object.keys(nets)) {
    for (const net of nets[name]) {
      if (net.family === "IPv4" && !net.internal) {
        console.log(`→  http://${net.address}:${PORT}`);
      }
    }
  }

  console.log("\nNamespaces:");
  console.log("→ Python : ws://<server-ip>:3000/python");
  console.log("→ App    : ws://<server-ip>:3000/app");
  console.log("→ Test UI: http://<server-ip>:3000/test\n");
});
