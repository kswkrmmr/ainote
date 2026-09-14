import { buttonVariants } from '@/components/ui/button'
import { cn } from '@/lib/utils'

// LINEへの導線だと一目で分かるよう、アプリ内の配色ではなくLINE公式のブランドカラーを使う
export const lineButtonClass = cn(buttonVariants(), 'bg-[#06C755] text-white hover:bg-[#05B34C]')

// 開発用と本番用で公式アカウントが異なるため、環境変数で切り替える
export const lineFriendUrl = import.meta.env.VITE_LINE_FRIEND_URL
