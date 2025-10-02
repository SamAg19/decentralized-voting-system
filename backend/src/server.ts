import express from "express";
import dotenv from "dotenv";
import votingRoutes from "./routes/voting.js";
import { errorHandler } from "./middleware/errorHandler.js";

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use("/api", votingRoutes);

// Health check endpoint
app.get("/health", (req, res) => {
  res.json({
    success: true,
    message: "Voting API is running",
    timestamp: new Date().toISOString(),
  });
});

app.use(errorHandler);

app.listen(PORT, () => {
  console.log(`Voting API server running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
  console.log(`\nAvailable endpoints:`);
  console.log(`  POST   http://localhost:${PORT}/api/candidates/add`);
  console.log(`  GET    http://localhost:${PORT}/api/candidates`);
  console.log(`  POST   http://localhost:${PORT}/api/vote`);
  console.log(`  GET    http://localhost:${PORT}/api/winner`);
});

export default app;
