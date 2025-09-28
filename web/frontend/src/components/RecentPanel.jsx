function RecentPanel({ recent = [], onSelect }) {
  return (
    <aside className="self-start md:sticky md:top-4">
      <div
        className="
          rounded-md border 
          bg-[#fff7e5] border-[#f0dc99]
          w-full max-w-[320px]
        "
      >
        <div className="px-4 py-3 border-b border-[#f0dc99]">
          <h3 className="text-[1.1rem] font-semibold text-[#3b4045]">
            Recent searches
          </h3>
        </div>
        <ul className="px-5 py-3 space-y-2 text-sm">
          {recent.length > 0 ? (
            recent.map((r, i) => (
              <li key={i} className="flex gap-2 items-start">
                <span className="mt-1 h-1.5 w-1.5 rounded-full bg-[#0b0b0b] shrink-0" />
                <button
                  className="text-left text-[#0b0b0b] hover:underline leading-5"
                  onClick={() => onSelect?.(r.question)}
                  title="Fill the search box with this query"
                >
                  {r.question}
                </button>
              </li>
            ))
          ) : (
            <li className="text-gray-500">No recent searches.</li>
          )}
        </ul>
      </div>
    </aside>
  );
}
export default RecentPanel;
