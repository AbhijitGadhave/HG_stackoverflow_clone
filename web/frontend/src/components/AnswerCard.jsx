import DOMPurify from "dompurify";

function AnswerCard({ ans }) {
  const html = DOMPurify.sanitize(ans.body || "");

  return (
    <li className="so-card p-4">
      <div className="flex gap-4">
        <div className="vote-box">
          <div className="vote-score">{ans.score ?? 0}</div>
          <div className="text-xs">score</div>
          {ans.is_accepted ? (
            <div className="mt-2 badge-accepted">accepted</div>
          ) : null}
        </div>
        <div className="flex-1 min-w-0">
          <div
            className="prose prose-sm sm:prose"
            dangerouslySetInnerHTML={{ __html: html }}
          />
          <div className="mt-3 flex items-center gap-3 text-xs text-gray-600">
            {ans.owner && <span>answered by <span className="text-gray-800">{ans.owner}</span></span>}
          </div>
        </div>
      </div>
    </li>
  );
}
export default AnswerCard;
