import './Contact.css'

export default function Contact() {
  return (
    <section id="contact" className="contact">
      <div className="container">
        <h2 className="section-title">contacts</h2>

        <div className="contact-grid">
          <div className="contact-text-area">
            <p className="contact-text">
              I'm interested in freelance opportunities and exciting projects. However, 
              if you have any other requests or questions, don't hesitate to contact me!
            </p>
          </div>

          <div className="contact-box-area">
            <div className="message-box">
              <h3 className="message-box-title">Message me here</h3>
              
              <div className="contact-methods-list">
                <a href="mailto:mguida2604@gmail.com" className="contact-method-item">
                  <span className="contact-icon">✉️</span>
                  <span className="contact-detail">mguida2604@gmail.com</span>
                </a>
                
                <a href="https://linkedin.com/in/marcelloguida00" target="_blank" rel="noopener noreferrer" className="contact-method-item">
                  <span className="contact-icon">💼</span>
                  <span className="contact-detail">LinkedIn</span>
                </a>
                
                <div className="contact-method-item">
                  <span className="contact-icon">📱</span>
                  <span className="contact-detail">+39 345 668 3621</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
