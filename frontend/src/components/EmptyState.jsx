import aiCharacter from '@/assets/ai-character.png'

function EmptyState({ children }) {
  return (
    <div className="empty-state">
      <img src={aiCharacter} alt="" className="empty-state-character" />
      <p className="form-hint">{children}</p>
    </div>
  )
}

export default EmptyState
