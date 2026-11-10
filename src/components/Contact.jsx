import { useState } from 'react'
import SectionTab from './SectionTab'
import { useLanguage } from '../i18n/useLanguage'
import './Contact.css'

export default function Contact() {
  const { t } = useLanguage()
  const c = t.contact
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [isSubmitted, setIsSubmitted] = useState(false)
  const [error, setError] = useState(null)

  const handleSubmit = async (e) => {
    e.preventDefault()
    setIsSubmitting(true)
    setError(null)

    const form = e.target
    const formData = new FormData(form)

    try {
      const response = await fetch('https://formsubmit.co/ajax/mguida2604@gmail.com', {
        method: 'POST',
        body: formData,
      })

      if (response.ok) {
        setIsSubmitted(true)
        form.reset()
      } else {
        setError(c.errorGeneric)
      }
    } catch {
      setError(c.errorNetwork)
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <section id="contact" className="contact-wow reveal">
      <div className="container">
        <SectionTab
          file="Contact.swift"
          comment={c.comment}
          dotColor="var(--accent-green)"
        />

        <div className="contact-grid-wow">
          <div className="contact-info-glass">
            <h2 className="contact-title">{c.title}</h2>
            <p className="contact-text-wow">{c.text}</p>

            <div className="contact-methods">
              <a href="mailto:mguida2604@gmail.com" className="method-glass">
                <span className="method-icon">✉</span>
                <div>
                  <span className="method-label">{c.email}</span>
                  <span className="method-value">mguida2604@gmail.com</span>
                </div>
              </a>
              <a
                href="https://linkedin.com/in/marcelloguida00"
                target="_blank"
                rel="noopener noreferrer"
                className="method-glass"
              >
                <span className="method-icon">in</span>
                <div>
                  <span className="method-label">{c.linkedin}</span>
                  <span className="method-value">marcelloguida00</span>
                </div>
              </a>
              <div className="method-glass">
                <span className="method-icon">☎</span>
                <div>
                  <span className="method-label">{c.phone}</span>
                  <span className="method-value">+39 345 668 3621</span>
                </div>
              </div>
            </div>
          </div>

          <div className="contact-form-glass">
            {isSubmitted ? (
              <div className="success-message-wow">
                <span className="success-icon">✓</span>
                <h3>{c.successTitle}</h3>
                <p>{c.successText}</p>
                <button
                  onClick={() => setIsSubmitted(false)}
                  className="btn btn-secondary mt-4"
                >
                  {c.sendAnother}
                </button>
              </div>
            ) : (
              <form onSubmit={handleSubmit} className="wow-form">
                <input type="hidden" name="_subject" value={c.subject} />
                <input type="hidden" name="_captcha" value="false" />
                <input type="hidden" name="_template" value="table" />

                <div className="form-group">
                  <label htmlFor="name">{c.name}</label>
                  <input
                    id="name"
                    type="text"
                    name="name"
                    placeholder={c.namePlaceholder}
                    required
                    className="form-input"
                    disabled={isSubmitting}
                  />
                </div>
                <div className="form-group">
                  <label htmlFor="email">{c.emailLabel}</label>
                  <input
                    id="email"
                    type="email"
                    name="email"
                    placeholder={c.emailPlaceholder}
                    required
                    className="form-input"
                    disabled={isSubmitting}
                  />
                </div>
                <div className="form-group">
                  <label htmlFor="message">{c.message}</label>
                  <textarea
                    id="message"
                    name="message"
                    placeholder={c.messagePlaceholder}
                    required
                    rows="5"
                    className="form-input textarea"
                    disabled={isSubmitting}
                  ></textarea>
                </div>

                {error && <p className="error-text-wow">{error}</p>}

                <button
                  type="submit"
                  className="btn btn-primary submit-btn"
                  disabled={isSubmitting}
                >
                  {isSubmitting ? c.sending : c.send}
                </button>
              </form>
            )}
          </div>
        </div>
      </div>
    </section>
  )
}
