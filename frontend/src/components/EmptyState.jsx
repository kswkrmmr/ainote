import aiCharacter from '@/assets/ai-character.png'

function EmptyState({ children }) {
  return (
    <div className="empty-state">
      <img src={aiCharacter} alt="" className="empty-state-character" />
      <p className="empty-state-bubble">{children}</p>
    </div>
  )
}

export default EmptyState
