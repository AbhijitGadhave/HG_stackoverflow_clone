function Tabs({ active, onChange }) {
  const base =
    "px-3 py-2 rounded border text-sm transition-colors whitespace-nowrap";
  const activeCls = "bg-blue-50 border-blue-300";
  const inactiveCls = "bg-white border-gray-300 hover:bg-gray-50";

  return (
    <div className="mb-4 flex items-center gap-2">
      <button
        onClick={() => onChange("original")}
        className={`${base} ${active === "original" ? activeCls : inactiveCls}`}
      >
        Original
      </button>
      <button
        onClick={() => onChange("reranked")}
        className={`${base} ${active === "reranked" ? activeCls : inactiveCls}`}
      >
        LLM Reranked
      </button>
    </div>
  );
}
export default Tabs;
