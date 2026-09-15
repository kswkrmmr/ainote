import { buildLineShareUrl } from '@/lib/invitation'
import { lineButtonClass } from '@/lib/line'

function LineShareButton({ message }) {
  return (
    <a
      href={buildLineShareUrl(message)}
      target="_blank"
      rel="noopener noreferrer"
      className={lineButtonClass}
    >
      LINEで送る
    </a>
  )
}

export default LineShareButton
