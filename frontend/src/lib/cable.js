import { createConsumer } from '@rails/actioncable'

export function createCableConsumer(apiBaseUrl, token) {
  const cableUrl = `${apiBaseUrl.replace(/^http/, 'ws')}/cable?token=${encodeURIComponent(token)}`
  return createConsumer(cableUrl)
}
