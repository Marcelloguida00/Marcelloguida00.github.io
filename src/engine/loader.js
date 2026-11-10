import gsap from 'gsap'
import { ease, prefersReducedMotion } from './env'

export function runLoader() {
  const loader = document.getElementById('loader')
  if (!loader) {
    document.documentElement.classList.add('is-loaded')
    return Promise.resolve()
  }

  if (prefersReducedMotion()) {
    loader.hidden = true
    document.documentElement.classList.add('is-loaded')
    return Promise.resolve()
  }

  const count = loader.querySelector('[data-loader-count]')
  const bar = loader.querySelector('[data-loader-bar]')
  const state = { n: 0 }

  return new Promise((resolve) => {
    const tl = gsap.timeline({
      onComplete() {
        gsap.to(loader, {
          autoAlpha: 0,
          duration: 0.55,
          ease: ease.out,
          onComplete() {
            loader.hidden = true
            document.documentElement.classList.add('is-loaded')
            resolve()
          },
        })
      },
    })

    tl.to(state, {
      n: 100,
      duration: 1.35,
      ease: 'power2.inOut',
      onUpdate() {
        const v = Math.round(state.n)
        if (count) count.textContent = String(v).padStart(3, '0')
        if (bar) bar.style.transform = `scaleX(${state.n / 100})`
      },
    })
  })
}
