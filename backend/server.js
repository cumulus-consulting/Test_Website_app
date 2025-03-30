const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json());

const mongoUser = process.env.MONGO_USERNAME || "admin";
const mongoPass = process.env.MONGO_PASSWORD || "password";
const mongoHost = process.env.MONGO_HOST || "10.0.3.50";  
const mongoPort = process.env.MONGO_PORT || "27017";
const mongoDb   = process.env.MONGO_DB   || "mydatabase";

const connectionString = `mongodb://${mongoUser}:${mongoPass}@${mongoHost}:${mongoPort}/${mongoDb}?authSource=admin`;

mongoose.connect(connectionString, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});


const todoSchema = new mongoose.Schema({
  text: String,
});

const Todo = mongoose.model("Todo", todoSchema);


app.get("/api/todos", async (req, res) => {
  try {
    const todos = await Todo.find();
    res.json(todos);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal server error" });
  }
});

app.post("/api/todos", async (req, res) => {
  try {
    const newTodo = new Todo({ text: req.body.text });
    await newTodo.save();
    res.status(201).json(newTodo);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal server error" });
  }
});

app.delete("/api/todos/:id", async (req, res) => {
  try {
    await Todo.findByIdAndDelete(req.params.id);
    res.status(204).end(); 
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal server error" });
  }
});

const port = process.env.PORT || 3000;
app.listen(port, () => {
  console.log(`Todo backend listening on port ${port}`);
});
