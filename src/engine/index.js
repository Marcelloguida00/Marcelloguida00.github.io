import { initScroll } from './scroll'
import { createSignalDriver } from './signal'
import { initReveals, playIntro } from './reveal'
import { runLoader } from './loader'
import { prefersReducedMotion } from './env'

let cleanupScroll = null
let cleanupReveal = null
let signal = null
let booting = null

export async function boot() {
  if (booting) return booting

  booting = (async () => {
    const root = document.documentElement
    root.classList.add('js')
    if (!prefersReducedMotion()) root.classList.add('motion')

    signal = createSignalDriver()
    cleanupScroll = initScroll(({ progress }) => signal?.setProgress(progress))
    cleanupReveal = initReveals(document)

    await runLoader()
    playIntro(document)
  })()

  try {
    await booting
  } finally {
    booting = null
  }
}

export function teardown() {
  cleanupScroll?.()
  cleanupReveal?.()
  signal?.destroy()
  cleanupScroll = null
  cleanupReveal = null
  signal = null
}

export { initReveals, playIntro }
