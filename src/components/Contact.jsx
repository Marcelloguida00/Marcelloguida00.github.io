import { useState } from 'react'
import SectionTab from './SectionTab'
import './Contact.css'

export default function Contact() {
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
        setError('Something went wrong. Please try again.')
      }
    } catch (err) {
      setError('Failed to send message. Please try again later.')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <section id="contact" className="contact-wow reveal">
      <div className="container">
        <SectionTab
          file="Contact.swift"
          comment="// say hello"
          dotColor="var(--accent-green)"
        />

        <div className="contact-grid-wow">
          <div className="contact-info-glass">
            <h2 className="contact-title">Let's build something.</h2>
            <p className="contact-text-wow">
              I'm always open to discussing new projects, creative ideas, or
              opportunities to be part of your vision. My inbox is open — reach out.
            </p>

            <div className="contact-methods">
              <a href="mailto:mguida2604@gmail.com" className="method-glass">
                <span className="method-icon">✉</span>
                <div>
                  <span className="method-label">Email</span>
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
                  <span className="method-label">LinkedIn</span>
                  <span className="method-value">marcelloguida00</span>
                </div>
              </a>
              <div className="method-glass">
                <span className="method-icon">☎</span>
                <div>
                  <span className="method-label">Phone</span>
                  <span className="method-value">+39 345 668 3621</span>
                </div>
              </div>
            </div>
          </div>

          <div className="contact-form-glass">
            {isSubmitted ? (
              <div className="success-message-wow">
                <span className="success-icon">✓</span>
                <h3>Message sent</h3>
                <p>Thanks for reaching out — I'll get back to you as soon as possible.</p>
                <button onClick={() => setIsSubmitted(false)} className="btn btn-secondary mt-4">
                  Send another
                </button>
              </div>
            ) : (
              <form onSubmit={handleSubmit} className="wow-form">
                <input type="hidden" name="_subject" value="New message from your portfolio!" />
                <input type="hidden" name="_captcha" value="false" />
                <input type="hidden" name="_template" value="table" />

                <div className="form-group">
                  <label htmlFor="name">Name</label>
                  <input
                    id="name"
                    type="text"
                    name="name"
                    placeholder="Your name"
                    required
                    className="form-input"
                    disabled={isSubmitting}
                  />
                </div>
                <div className="form-group">
                  <label htmlFor="email">Email</label>
                  <input
                    id="email"
                    type="email"
                    name="email"
                    placeholder="you@example.com"
                    required
                    className="form-input"
                    disabled={isSubmitting}
                  />
                </div>
                <div className="form-group">
                  <label htmlFor="message">Message</label>
                  <textarea
                    id="message"
                    name="message"
                    placeholder="Tell me about your project"
                    required
                    rows="5"
                    className="form-input textarea"
                    disabled={isSubmitting}
                  ></textarea>
                </div>

                {error && <p className="error-text-wow">{error}</p>}

                <button type="submit" className="btn btn-primary submit-btn" disabled={isSubmitting}>
                  {isSubmitting ? 'Sending…' : 'Send message'}
                </button>
              </form>
            )}
          </div>
        </div>
      </div>
    </section>
  )
}
