import { buttonVariants } from '@/components/ui/button'
import { buildLineShareUrl } from '@/lib/invitation'
import { cn } from '@/lib/utils'

// LINEへの導線だと一目で分かるよう、アプリ内の配色ではなくLINE公式のブランドカラーを使う
const lineShareButtonClass = cn(buttonVariants(), 'bg-[#06C755] text-white hover:bg-[#05B34C]')

function LineShareButton({ message }) {
  return (
    <a
      href={buildLineShareUrl(message)}
      target="_blank"
      rel="noopener noreferrer"
      className={lineShareButtonClass}
    >
      LINEで送る
    </a>
  )
}

export default LineShareButton
