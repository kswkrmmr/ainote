import { useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { getToken, clearToken } from './auth'

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'

export function apiUrl(path) {
  return `${apiBaseUrl}${path}`
}

// 401をそのまま返す素のリクエスト。ログインの失敗や未ログインでの招待確認のように、
// 401が異常ではないページはこちらを使う。
// body は FormData ならそのまま、それ以外のオブジェクトならJSONとして送る。
export function apiFetch(path, { method = 'GET', body, auth = true } = {}) {
  const headers = {}

  if (auth) {
    headers.Authorization = `Bearer ${getToken()}`
  }

  let requestBody = body

  if (body !== undefined && !(body instanceof FormData)) {
    headers['Content-Type'] = 'application/json'
    requestBody = JSON.stringify(body)
  }

  return fetch(apiUrl(path), { method, headers, body: requestBody })
}

// ログインが前提のページ用。401ならトークンを捨ててログイン画面へ送り、null を返す。
// 呼び出し側は `if (!response) return` で抜ける。
export function useApi() {
  const navigate = useNavigate()

  return useCallback(
    async (path, options) => {
      const response = await apiFetch(path, options)

      if (response.status === 401) {
        clearToken()
        navigate('/login')
        return null
      }

      return response
    },
    [navigate],
  )
}

// サーバーが500を返すとき、このAPIはpublic/500.htmlを持たないため本文が空になる。
// response.json() が例外になり「通信エラー」と誤表示されるのを避けるため、
// JSONとして読めなければ null を返す。
export async function readJson(response) {
  try {
    return await response.json()
  } catch {
    return null
  }
}
