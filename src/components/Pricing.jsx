import { useEffect, useRef, useState } from 'react'
import SectionTab from './SectionTab'
import { useLanguage } from '../i18n/useLanguage'
import './Pricing.css'

export default function Pricing() {
  const { t, lang } = useLanguage()
  const copy = t.pricing
  const categories = copy.categories

  const [activeCategory, setActiveCategory] = useState(categories[0].id)
  const [activeService, setActiveService] = useState(0)
  const [panelKey, setPanelKey] = useState(0)
  const listRef = useRef(null)

  const resolvedCategoryId = categories.some((c) => c.id === activeCategory)
    ? activeCategory
    : categories[0].id
  const category = categories.find((c) => c.id === resolvedCategoryId) ?? categories[0]
  const safeServiceIndex = Math.min(activeService, category.services.length - 1)
  const service = category.services[safeServiceIndex]

  const selectCategory = (id) => {
    setActiveCategory(id)
    setActiveService(0)
    setPanelKey((k) => k + 1)
  }

  useEffect(() => {
    const el = listRef.current
    if (!el) return
    const items = el.querySelectorAll('.pricing-service')
    items.forEach((item, i) => {
      item.style.setProperty('--stagger', `${i * 60}ms`)
    })
  }, [resolvedCategoryId, panelKey, lang, category.services])

  return (
    <section id="pricing" className="pricing-wow reveal">
      <div className="container">
        <div className="pricing-intro">
          <SectionTab
            file="Pricing.swift"
            comment={copy.comment}
            dotColor="var(--accent-secondary)"
          />
          <h2 className="pricing-title">
            {copy.titleBefore}{' '}
            <span className="text-accent">{copy.titleAccent}</span>
            {copy.titleAfter}
          </h2>
          <p className="pricing-lead">{copy.lead}</p>
        </div>

        <div className="pricing-rates" aria-label={copy.ratesAria}>
          {copy.rates.map((rate, idx) => (
            <article
              className="pricing-rate reveal-child"
              key={rate.id}
              style={{
                '--rate-delay': `${idx * 90}ms`,
                '--reveal-delay': `${idx * 70}ms`,
              }}
            >
              <span className="pricing-rate-label">{rate.label}</span>
              <div className="pricing-rate-value">
                <span className="pricing-rate-amount">{rate.range}</span>
                <span className="pricing-rate-unit">{rate.unit}</span>
              </div>
              <p className="pricing-rate-note">{rate.note}</p>
            </article>
          ))}
        </div>

        <div className="pricing-studio">
          <div className="pricing-tabs" role="tablist" aria-label={copy.categoriesAria}>
            {categories.map((cat) => {
              const selected = cat.id === resolvedCategoryId
              return (
                <button
                  key={cat.id}
                  type="button"
                  role="tab"
                  id={`pricing-tab-${cat.id}`}
                  aria-selected={selected}
                  aria-controls="pricing-panel"
                  className={`pricing-tab ${selected ? 'is-active' : ''}`}
                  style={{ '--tab-accent': cat.accent }}
                  onClick={() => selectCategory(cat.id)}
                >
                  <span className="pricing-tab-index">{cat.index}</span>
                  <span className="pricing-tab-copy">
                    <span className="pricing-tab-title">{cat.title}</span>
                    <span className="pricing-tab-sub">{cat.subtitle}</span>
                  </span>
                </button>
              )
            })}
          </div>

          <div
            className="pricing-panel"
            id="pricing-panel"
            role="tabpanel"
            aria-labelledby={`pricing-tab-${category.id}`}
            key={`${lang}-${panelKey}`}
            style={{ '--panel-accent': category.accent }}
          >
            <header className="pricing-panel-head">
              <div>
                <p className="pricing-panel-kicker">{category.subtitle}</p>
                <h3 className="pricing-panel-title">{category.title}</h3>
              </div>
              <div className="pricing-featured" aria-live="polite">
                <span className="pricing-featured-label">{service.name}</span>
                <span
                  className="pricing-featured-price"
                  key={`${category.id}-${safeServiceIndex}-price`}
                >
                  {service.price}
                </span>
              </div>
            </header>

            <div className="pricing-split">
              <ul className="pricing-services" ref={listRef}>
                {category.services.map((item, idx) => {
                  const isActive = idx === safeServiceIndex
                  return (
                    <li key={item.name}>
                      <button
                        type="button"
                        className={`pricing-service ${isActive ? 'is-active' : ''}`}
                        onClick={() => setActiveService(idx)}
                        onMouseEnter={() => setActiveService(idx)}
                        onFocus={() => setActiveService(idx)}
                        aria-current={isActive ? 'true' : undefined}
                      >
                        <span className="pricing-service-index">
                          {String(idx + 1).padStart(2, '0')}
                        </span>
                        <span className="pricing-service-body">
                          <span className="pricing-service-name">{item.name}</span>
                          <span className="pricing-service-price">{item.price}</span>
                        </span>
                        <span className="pricing-service-rail" aria-hidden="true" />
                      </button>
                    </li>
                  )
                })}
              </ul>

              <aside
                className="pricing-detail"
                key={`${category.id}-${safeServiceIndex}-${lang}`}
              >
                <p className="pricing-detail-label">{copy.includesLabel}</p>
                <p className="pricing-detail-text">{service.includes}</p>
                <div className="pricing-detail-footer">
                  <div>
                    <p className="pricing-detail-meta">{copy.indicativeLabel}</p>
                    <p className="pricing-detail-amount">{service.price}</p>
                  </div>
                  <a href="#contact" className="btn-signal pricing-cta">
                    <span className="btn-signal__fill" aria-hidden="true" />
                    <span className="btn-signal__label">{copy.cta}</span>
                  </a>
                </div>
              </aside>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
