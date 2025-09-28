import { useEffect, useMemo, useState } from "react";
import { searchQuestion, getRecent } from "../api";
import Header from "../components/Header";
import Tabs from "../components/Tabs";
import AnswerList from "../components/AnswerList";
import RecentPanel from "../components/RecentPanel";

function Home() {
  const [q, setQ] = useState("");
  const [activeTab, setActiveTab] = useState("original");
  const [loading, setLoading] = useState(false);
  const [resp, setResp] = useState(null);
  const [recent, setRecent] = useState([]);

  useEffect(() => {
    getRecent().then(setRecent).catch(() => setRecent([]));
  }, []);

  async function onSearch(e) {
    e?.preventDefault();
    if (!q.trim()) return;

    setLoading(true);
    setResp(null);

    try {
      const data = await searchQuestion(q);
      setResp(data);
      setRecent(await getRecent());
    } catch {
      setResp({ error: "Failed to fetch answers. Check API & CORS." });
    } finally {
      setLoading(false);
    }
  }

  const items = useMemo(() => {
    if (!resp) return [];
    const bag =
      activeTab === "original" ? resp.original_answers : resp.reranked_answers;
    return Array.isArray(bag) ? bag : [];
  }, [resp, activeTab]);

  return (
    <div className="min-h-screen bg-[#f1f2f3] text-[#232629]">
      <div className="h-1.5" style={{ backgroundColor: "var(--so-brand)" }} />

      <Header q={q} setQ={setQ} onSearch={onSearch} loading={loading} />

      <main className="max-w-6xl mx-auto px-4 py-6 grid grid-cols-1 md:grid-cols-[minmax(0,1fr)_320px] gap-6 items-start">
        <section>
          <Tabs active={activeTab} onChange={setActiveTab} />

          {!resp && (
            <p className="text-gray-600">Search for something to see answers.</p>
          )}
          {resp?.error && <p className="text-red-600">{resp.error}</p>}

          {loading ? (
            <p className="text-gray-700">Loading…</p>
          ) : (
            <AnswerList items={items} />
          )}
        </section>

        <RecentPanel
          recent={recent}
          onSelect={(question) => {
            setQ(question);
          }}
        />
      </main>
    </div>
  );
}
export default Home;