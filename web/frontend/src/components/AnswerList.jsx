import AnswerCard from "./AnswerCard";

function AnswerList({ items }) {
  if (!items || items.length === 0) {
    return <p className="text-gray-600">No answers found.</p>;
  }
  return (
    <ul className="space-y-3">
      {items.map((a) => (
        <AnswerCard key={a.answer_id ?? Math.random()} ans={a} />
      ))}
    </ul>
  );
}
export default AnswerList;