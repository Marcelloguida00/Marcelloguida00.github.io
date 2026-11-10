import { useEffect, useState } from 'react'
import { translations } from './translations'
import { LanguageContext } from './context'

const STORAGE_KEY = 'mg-lang'

function detectInitialLang() {
  try {
    const params = new URLSearchParams(window.location.search)
    const fromQuery = params.get('lang')
    if (fromQuery === 'it' || fromQuery === 'en') return fromQuery
  } catch {
    /* ignore */
  }
  try {
    const saved = localStorage.getItem(STORAGE_KEY)
    if (saved === 'it' || saved === 'en') return saved
  } catch {
    /* ignore */
  }
  if (typeof navigator !== 'undefined' && navigator.language?.toLowerCase().startsWith('it')) {
    return 'it'
  }
  return 'en'
}

export function LanguageProvider({ children }) {
  const [lang, setLangState] = useState(detectInitialLang)

  const setLang = (next) => {
    const value = next === 'it' ? 'it' : 'en'
    setLangState(value)
    try {
      localStorage.setItem(STORAGE_KEY, value)
    } catch {
      /* ignore */
    }
  }

  const toggleLang = () => setLang(lang === 'it' ? 'en' : 'it')

  useEffect(() => {
    document.documentElement.lang = lang
  }, [lang])

  const t = translations[lang]

  return (
    <LanguageContext.Provider value={{ lang, setLang, toggleLang, t }}>
      {children}
    </LanguageContext.Provider>
  )
}
