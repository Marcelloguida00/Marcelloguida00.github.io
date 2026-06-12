document.addEventListener('DOMContentLoaded', () => {
    
    // Navbar scroll effect
    const navbar = document.querySelector('.navbar');
    
    window.addEventListener('scroll', () => {
        if (window.scrollY > 50) {
            navbar.classList.add('scrolled');
        } else {
            navbar.classList.remove('scrolled');
        }
    });

    // Mobile Menu Toggle
    const menuBtn = document.getElementById('menuToggle');
    const mobileMenu = document.getElementById('mobileMenu');
    const mobileLinks = document.querySelectorAll('.mobile-link');
    let menuOpen = false;

    if(menuBtn && mobileMenu) {
        menuBtn.addEventListener('click', () => {
            menuOpen = !menuOpen;
            if(menuOpen) {
                mobileMenu.classList.add('active');
                // Transform hamburger to X
                menuBtn.children[0].style.transform = 'rotate(45deg) translate(5px, 5px)';
                menuBtn.children[1].style.opacity = '0';
                menuBtn.children[2].style.transform = 'rotate(-45deg) translate(5px, -5px)';
            } else {
                mobileMenu.classList.remove('active');
                // Reset hamburger
                menuBtn.children[0].style.transform = 'none';
                menuBtn.children[1].style.opacity = '1';
                menuBtn.children[2].style.transform = 'none';
            }
        });

        // Close menu on link click
        mobileLinks.forEach(link => {
            link.addEventListener('click', () => {
                menuOpen = false;
                mobileMenu.classList.remove('active');
                menuBtn.children[0].style.transform = 'none';
                menuBtn.children[1].style.opacity = '1';
                menuBtn.children[2].style.transform = 'none';
            });
        });
    }

    // Scroll Reveal Intersection Observer
    const revealElements = document.querySelectorAll('.reveal, .reveal-up, .reveal-left, .reveal-right');

    const revealOptions = {
        threshold: 0.15,
        rootMargin: "0px 0px -50px 0px"
    };

    const revealOnScroll = new IntersectionObserver(function(entries, observer) {
        entries.forEach(entry => {
            if (!entry.isIntersecting) {
                return;
            } else {
                entry.target.classList.add('active');
                observer.unobserve(entry.target);
            }
        });
    }, revealOptions);

    revealElements.forEach(el => {
        revealOnScroll.observe(el);
    });

    // Contact Form Logic
    const contactForm = document.getElementById('contactForm');
    if(contactForm) {
        const submitBtn = contactForm.querySelector('button[type="submit"]');
        
        contactForm.addEventListener('submit', function(e) {
            e.preventDefault();
            
            // Disable button to prevent double clicks
            const originalText = submitBtn.textContent;
            submitBtn.textContent = "Sending...";
            submitBtn.disabled = true;
            
            // Get values
            const name = document.getElementById('name').value;
            const email = document.getElementById('email').value;
            const message = document.getElementById('message').value;
            
            // Send via FormSubmit AJAX
            fetch('https://formsubmit.co/ajax/mguida2604@gmail.com', {
                method: "POST",
                headers: { 
                    'Content-Type': 'application/json',
                    'Accept': 'application/json'
                },
                body: JSON.stringify({
                    name: name,
                    email: email,
                    message: message,
                    _subject: "New Message from World of Fables Website!",
                    _replyto: email
                })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success === "true" || data.success === true) {
                    // Show Success Overlay UI immediately
                    document.getElementById('formSuccess').style.display = 'flex';
                    
                    // Clear the form and reset button
                    contactForm.reset();
                } else {
                    console.error("FormSubmit Error:", data);
                    alert("Attenzione: il server ha bloccato l'invio. " + (data.message || "Devi usare un web server (localhost) o pubblicare il sito online."));
                }
                submitBtn.textContent = originalText;
                submitBtn.disabled = false;
            })
            .catch(error => {
                console.error("Error:", error);
                alert("Si è verificato un errore di connessione. Se stai testando da 'file://', il browser sta bloccando la richiesta. Usa un server web locale.");
                submitBtn.textContent = originalText;
                submitBtn.disabled = false;
            });
        });
    }

});
