# StackOverflow Clone with Phoenix + React + LLM Rerank

A full-stack application that lets users search questions via the Stack Overflow API, view answers in a React UI, and see re-ranked answers using a local LLM (Ollama). The app is containerized with Docker Compose and uses Postgres for caching recent queries.

---

## Features

* Search Stack Overflow questions and display answers
* View **original ranking** vs **LLM reranked** answers
* React UI closely modeled on a real Stack Overflow page
* Phoenix API backend (Elixir)
* Local LLM (via Ollama, e.g., `llama3:8b`) for reranking answers
* Postgres database storing last 5 searched questions
* Docker Compose setup for reproducible environment

---

## Requirements

* Docker Desktop / Docker Engine + Compose v2
* `.env` file with required environment variables

---

## Setup

### 1. Environment Variables

Create a `.env` file in the repo root with:

```bash
POSTGRES_DB=api_dev
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
DATABASE_URL=ecto://postgres:postgres@db:5432/api_dev
POOL_SIZE=10
STACKEXCHANGE_KEY=
STACKEXCHANGE_SITE=stackoverflow
PHX_PORT=4000
WEB_PORT=5173
LLM_API_BASE=//ollama:11434/v1
LLM_API_KEY=ollama-no-key
LLM_MODEL=llama3:8b
SECRET_KEY_BASE=

```

Generate `SECRET_KEY_BASE`:

```bash
mix phx.gen.secret
```

---

### 2. Build Images

```bash
docker compose build
```

---

### 3. Start Infra (DB + Ollama)

```bash
docker compose up -d db ollama
```

Check health:

```bash
docker inspect --format='{{.State.Health.Status}}' soclone_db
docker inspect --format='{{.State.Health.Status}}' soclone_ollama
```

---

### 4. Pull LLM Model

```bash
docker compose exec ollama ollama pull llama3:8b
docker compose exec ollama ollama list
```

---

### 5. Start App Services

```bash
docker compose up -d api web
```

Logs:

```bash
docker compose logs -f api
```

---

### 6. Verify

API root:

```bash
curl -i http://localhost:4000/
```

Search endpoint:

```bash
curl -s -X POST http://localhost:4000/api/search \
  -H 'content-type: application/json' \
  -d '{"anon_id":"cli-test","question":"How to sort a list of strings?"}' | jq .
```

UI:

```
http://localhost:5173
```

---

## Reset & Rebuild (if needed)

```bash
docker compose down -v --remove-orphans
docker system prune -f
docker compose build --no-cache
docker compose up -d db ollama
docker compose exec ollama ollama pull llama3:8b
docker compose up -d api web
```

---

## Architecture

* **Frontend:** React (Vite) — runs on port 5173
* **Backend:** Phoenix API (Elixir) — runs on port 4000
* **Database:** Postgres — runs on port 5432
* **LLM Service:** Ollama — runs on port 11434

---


