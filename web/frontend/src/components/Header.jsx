function Header({ q, setQ, onSearch, loading }) {
  return (
    <header className="bg-white border-b">
      <div className="max-w-6xl mx-auto px-4 py-3 flex items-center gap-4">
        <a
          href="/"
          className="flex items-baseline gap-1 select-none"
          aria-label="Stack Overflow clone"
        >
          <span className="text-xl tracking-tight text-[#0b0b0b] font-light">
            stack
          </span>
          <span className="text-xl tracking-tight text-[#0b0b0b] font-medium">
            overflow
          </span>
          <span className="text-xl tracking-tight text-[#0b0b0b] font-medium">
            clone
          </span>
        </a>

        <form onSubmit={onSearch} className="flex-1 flex gap-2">
          <input
            className="flex-1 border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-200"
            placeholder="Ask a question…"
            value={q}
            onChange={(e) => setQ(e.target.value)}
          />
          <button
            disabled={loading}
            className="bg-[#0a95ff] text-white px-4 py-2 rounded-md disabled:opacity-50"
          >
            {loading ? "Searching…" : "Search"}
          </button>
        </form>
      </div>
    </header>
  );
}
export default Header;
