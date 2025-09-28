import axios from "axios";

const API_BASE = "http://localhost:4000";

const http = axios.create({
  baseURL: API_BASE,
  timeout: 15000,
  withCredentials: true
});

export async function searchQuestion(q) {
  const { data } = await http.get("/api/search", { params: { q } });
  return data;
}

export async function getRecent() {
  const { data } = await http.get("/api/recent");
  if (Array.isArray(data.recent)) return data.recent;
  if (Array.isArray(data.items)) return data.items;
  return [];
}
