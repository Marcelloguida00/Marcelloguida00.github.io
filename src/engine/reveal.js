import gsap from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'
import { ease, prefersReducedMotion } from './env'

gsap.registerPlugin(ScrollTrigger)

export function initReveals(scope = document) {
  if (prefersReducedMotion()) {
    scope.querySelectorAll('[data-reveal], [data-intro]').forEach((el) => {
      el.classList.add('is-revealed')
    })
    return () => {}
  }

  const ctx = gsap.context(() => {
    scope.querySelectorAll('[data-reveal]').forEach((el) => {
      const type = el.getAttribute('data-reveal') || 'up'
      const delay = Number(el.getAttribute('data-delay') || 0)
      const from =
        type === 'fade'
          ? { autoAlpha: 0 }
          : type === 'clip'
            ? { clipPath: 'inset(100% 0 0 0)', autoAlpha: 1 }
            : { y: 36, autoAlpha: 0 }

      gsap.from(el, {
        ...from,
        duration: type === 'clip' ? 1.25 : 1.05,
        delay,
        ease: ease.out,
        scrollTrigger: {
          trigger: el,
          start: 'top 88%',
          once: true,
        },
        onComplete: () => el.classList.add('is-revealed'),
      })
    })
  }, scope)

  return () => ctx.revert()
}

export function playIntro(scope = document) {
  if (prefersReducedMotion()) {
    scope.querySelectorAll('[data-intro]').forEach((el) => el.classList.add('is-revealed'))
    return null
  }

  const els = scope.querySelectorAll('[data-intro]')
  if (!els.length) return null

  const tl = gsap.timeline({ defaults: { ease: ease.out } })
  els.forEach((el, i) => {
    const delay = Number(el.getAttribute('data-delay') || 0)
    gsap.set(el, { autoAlpha: 1 })
    tl.from(
      el,
      {
        y: 28,
        autoAlpha: 0,
        duration: 1.05,
        onStart: () => el.classList.add('is-revealed'),
        onComplete: () => el.classList.add('is-revealed'),
      },
      0.08 + i * 0.07 + delay
    )
  })
  // Safety: never leave brand invisible if timeline is interrupted
  tl.eventCallback('onComplete', () => {
    els.forEach((el) => el.classList.add('is-revealed'))
  })
  return tl
}
