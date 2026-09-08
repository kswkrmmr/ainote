import { createConsumer } from '@rails/actioncable'
import { apiUrl } from './api'

export function createCableConsumer(token) {
  const cableUrl = apiUrl(`/cable?token=${encodeURIComponent(token)}`).replace(/^http/, 'ws')
  return createConsumer(cableUrl)
}
