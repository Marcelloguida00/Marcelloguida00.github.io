import { useEffect } from 'react'
import { useLanguage } from '../i18n/useLanguage'

const SITE = 'https://marcelloguida.com'

const META = {
  it: {
    title: 'Marcello Guida — Sviluppatore iOS, siti web e web app a Napoli',
    description:
      'Sviluppatore iOS e designer a Napoli. Siti web, web app, app mobile e backend con listino prezzi chiaro. Apple Developer Academy e vincitore Swift Student Challenge 2026.',
    ogTitle: 'Marcello Guida — Sviluppatore iOS, siti web e web app',
    ogDescription:
      'Listino chiaro per siti, web app, app mobile e backend. Freelance a Napoli, Apple Developer Academy, Swift Student Challenge 2026.',
    locale: 'it_IT',
  },
  en: {
    title: 'Marcello Guida — iOS developer, websites & web apps in Naples',
    description:
      'iOS developer and designer in Naples. Websites, web apps, mobile apps and backend with clear pricing. Apple Developer Academy alumnus and Swift Student Challenge 2026 winner.',
    ogTitle: 'Marcello Guida — iOS developer, websites & web apps',
    ogDescription:
      'Clear rates for websites, web apps, mobile apps and backend. Freelance in Naples. Apple Developer Academy · Swift Student Challenge 2026.',
    locale: 'en_US',
  },
}

function upsertMeta(selector, attrs) {
  let el = document.head.querySelector(selector)
  if (!el) {
    el = document.createElement('meta')
    document.head.appendChild(el)
  }
  Object.entries(attrs).forEach(([key, value]) => {
    el.setAttribute(key, value)
  })
}

function upsertLink(rel, href, extra = {}) {
  const selector = Object.entries(extra).reduce(
    (acc, [k, v]) => `${acc}[${k}="${v}"]`,
    `link[rel="${rel}"]`
  )
  let el = document.head.querySelector(selector)
  if (!el) {
    el = document.createElement('link')
    el.setAttribute('rel', rel)
    Object.entries(extra).forEach(([k, v]) => el.setAttribute(k, v))
    document.head.appendChild(el)
  }
  el.setAttribute('href', href)
}

export default function SeoHead() {
  const { lang } = useLanguage()

  useEffect(() => {
    const copy = META[lang] ?? META.it
    const hash = window.location.hash || ''
    const path = hash === '#pricing' ? '/#pricing' : '/'
    const canonical = `${SITE}${path === '/' ? '/' : path}`

    document.title = copy.title
    document.documentElement.lang = lang

    upsertMeta('meta[name="description"]', {
      name: 'description',
      content: copy.description,
    })
    upsertMeta('meta[property="og:title"]', {
      property: 'og:title',
      content: copy.ogTitle,
    })
    upsertMeta('meta[property="og:description"]', {
      property: 'og:description',
      content: copy.ogDescription,
    })
    upsertMeta('meta[property="og:locale"]', {
      property: 'og:locale',
      content: copy.locale,
    })
    upsertMeta('meta[property="og:url"]', {
      property: 'og:url',
      content: canonical,
    })
    upsertMeta('meta[property="og:image"]', {
      property: 'og:image',
      content: `${SITE}/og-cover.jpg`,
    })
    upsertMeta('meta[name="twitter:title"]', {
      name: 'twitter:title',
      content: copy.ogTitle,
    })
    upsertMeta('meta[name="twitter:description"]', {
      name: 'twitter:description',
      content: copy.ogDescription,
    })
    upsertMeta('meta[name="twitter:image"]', {
      name: 'twitter:image',
      content: `${SITE}/og-cover.jpg`,
    })

    upsertLink('canonical', canonical)
  }, [lang])

  useEffect(() => {
    const onHash = () => {
      const copy = META[lang] ?? META.it
      if (window.location.hash === '#pricing') {
        document.title =
          lang === 'it'
            ? 'Prezzi e servizi — Marcello Guida | Siti, web app, mobile'
            : 'Pricing & services — Marcello Guida | Web, apps, backend'
        upsertLink('canonical', `${SITE}/#pricing`)
      } else {
        document.title = copy.title
        upsertLink('canonical', `${SITE}/`)
      }
    }
    onHash()
    window.addEventListener('hashchange', onHash)
    return () => window.removeEventListener('hashchange', onHash)
  }, [lang])

  return null
}
