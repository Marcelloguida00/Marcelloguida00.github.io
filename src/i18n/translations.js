export const translations = {
  en: {
    nav: {
      home: 'home',
      about: 'about',
      experience: 'experience',
      skills: 'skills',
      work: 'work',
      pricing: 'pricing',
      contact: 'contact',
      cta: 'Contact',
      toggleMenu: 'Toggle menu',
      langLabel: 'Language',
    },
    hero: {
      badge: 'Available for new projects',
      titleBefore: 'Crafting',
      titleAccent: 'native',
      titleAfter: 'iOS experiences.',
      subtitle:
        'iOS developer and designer in Naples. Apple Developer Academy. Swift Student Challenge 2026 winner.',
      viewWork: 'View my work',
      viewPricing: 'See pricing',
      getInTouch: 'Get in touch',
      markers: {
        about: 'about',
        experience: 'experience',
        skills: 'skills',
        work: 'work',
        pricing: 'pricing',
        contact: 'contact',
      },
      photoAlt: 'Marcello Guida, iOS developer',
      codeRole: 'iOS Developer & Designer',
    },
    about: {
      comment: '// who I am',
      greeting: "Hi, I'm Marcello  - \nI build software that respects people.",
      p1: "I'm a Computer Science student at the University of Salerno (Fisciano) and an iOS developer currently sharpening my craft at the Apple Developer Academy, a joint program with Federico II University in Naples. I design and build responsive, native iOS applications from first sketch to shipped product.",
      p2: 'What keeps me at the keyboard is the gap between an idea and a working app: I like closing it carefully, with attention to performance, accessibility, and the small interactions most people never notice - but always feel.',
      facts: [
        { label: 'Based in', value: 'Naples, Italy' },
        { label: 'Studying', value: 'Computer Science · Fisciano (UNISA)' },
        { label: 'Academy', value: 'Apple Developer Academy · Federico II' },
        { label: 'Award', value: 'Swift Student Challenge 2026' },
      ],
      awardHighlight: 'Swift Student Challenge 2026 Winner',
    },
    experience: {
      comment: "// where I've been",
      items: [
        {
          title: 'Apple Developer Academy',
          company: 'Federico II University × Apple',
          location: 'Naples, Italy',
          period: 'Sep 2025 - Jun 2026',
          description:
            'Selective program focused on iOS development, product design, and entrepreneurial thinking. Building and shipping iOS apps with Swift and Xcode inside Agile-style team sprints.',
          highlights: ['iOS Development', 'Product Design', 'Swift', 'Xcode', 'Team Collaboration'],
          marker: 'work',
          current: true,
        },
        {
          title: 'Swift Student Challenge 2026',
          company: 'Apple · WWDC26',
          location: 'Remote',
          period: 'Feb 2026',
          description:
            'Selected as a winner with an interactive Swift playground built around accessibility and playful learning - shipped as a polished, App-Store-ready experience.',
          highlights: ['Swift Playgrounds', 'Accessibility', 'SwiftUI', 'Winner'],
          marker: 'award',
          current: false,
        },
        {
          title: 'B.Sc. Computer Science',
          company: 'University of Salerno (UNISA)',
          location: 'Fisciano, Italy',
          period: '2023 - Present',
          description:
            'Studying algorithms, software engineering, and machine learning while applying what I learn directly to native iOS projects and product design.',
          highlights: ['Algorithms', 'Software Engineering', 'Machine Learning', 'Databases'],
          marker: 'education',
          current: false,
        },
      ],
    },
    skills: {
      comment: '// what I use',
    },
    projects: {
      comment: '// shipped work',
      viewGithub: 'View GitHub',
      explore: 'Explore project',
      items: [
        {
          title: 'Echoes',
          subtitle: 'Swift Student Challenge',
          description:
            'Interactive story about exclusion, silence, and the courage to speak up - Winner of the Apple Swift Student Challenge 2026. Built with Swift Playgrounds for WWDC26.',
          tags: ['Swift', 'SwiftUI', 'Playgrounds', 'WWDC26'],
          link: '/echoes/index.html',
          cover: '/projects/echoes-cover.jpg',
        },
        {
          title: 'Polly',
          subtitle: 'Digital Eco-Companion',
          description:
            'A digital eco-companion that helps you understand and reduce Data Pollution: clean your photo library, learn the facts, and chat with on-device Apple Intelligence - all in private.',
          tags: ['Swift', 'iOS', 'Apple Intelligence', 'Sustainability'],
          link: '/marcelloguida-polly/indexPolly.html',
          cover: '/projects/marcelloguida-polly-cover.jpg',
        },
        {
          title: 'SyncPoint',
          subtitle: 'Tennis & Padel',
          description:
            'A Tennis and Padel scorekeeper for Apple Watch and iPhone: scoring on your wrist, live scoreboard, stats, Apple Health, and matches shared with opponents.',
          tags: ['Swift', 'watchOS', 'iOS', 'HealthKit'],
          link: '/syncpoint/syncpoint.html',
          cover: '/projects/syncpoint-cover.jpg',
        },
        {
          title: 'World of Fables',
          subtitle: 'Lumi',
          description:
            'An immersive iPad experience that turns classic fables into interactive games, built to teach logical sequencing to children with a deep focus on accessibility - removing barriers so every young mind can play.',
          tags: ['Swift', 'iPadOS', 'Accessibility', 'Game Design'],
          link: '/world-of-fables/index.html',
          cover: '/projects/world-of-fables-cover.jpg',
        },
      ],
    },
    pricing: {
      comment: '// clear rates, serious work',
      titleBefore: 'Rates built to',
      titleAccent: 'start strong',
      titleAfter: '.',
      lead:
        'A complete, competitive listino for websites, web apps, mobile, and backend - serious figures without underselling the craft.',
      ratesAria: 'Base rates & labour',
      rates: [
        {
          id: 'hourly',
          label: 'Hourly rate',
          range: '€18 - €25',
          unit: '/ hour',
          note: 'Small tweaks, edits, bug fixes',
        },
        {
          id: 'day',
          label: 'Work day (8 hours)',
          range: '€120 - €160',
          unit: '/ day',
          note: 'Full focus on one deliverable',
        },
        {
          id: 'pack',
          label: '10-hour pack',
          range: '€180',
          unit: ' prepaid',
          note: 'Ongoing support, ideal for retainers',
        },
      ],
      categoriesAria: 'Service categories',
      includesLabel: 'What’s included',
      indicativeLabel: 'Indicative price',
      cta: 'Request a quote',
      categories: [
        {
          id: 'web',
          index: '01',
          title: 'Websites',
          subtitle: 'Web Development',
          accent: 'var(--accent-color)',
          services: [
            {
              name: 'Landing Page / One-Page',
              includes:
                'Single promotional or event page, responsive (phone/desktop), email contact form, map, modern visuals.',
              price: '€180 - €300',
            },
            {
              name: 'Brochure site (4-5 pages)',
              includes:
                'Home, About, Services, Contact, Privacy Policy. Built on WordPress or modern static code.',
              price: '€350 - €600',
            },
            {
              name: 'Dynamic site with CMS',
              includes:
                'Product catalogue (no direct sales), blog or news area the client can manage from an admin panel.',
              price: '€500 - €850',
            },
            {
              name: 'Base e-commerce',
              includes:
                'Shopify / WooCommerce. Up to 20-30 products loaded, cart, payments (Stripe/PayPal), basic shipping setup and order notifications.',
              price: '€650 - €1,100',
            },
          ],
        },
        {
          id: 'fullstack',
          index: '02',
          title: 'Web App',
          subtitle: 'Custom full-stack',
          accent: 'var(--accent-secondary)',
          services: [
            {
              name: 'Base dashboard / user portal',
              includes:
                'Login/Registration (JWT/Sessions), profile management, relational or NoSQL database, data tables and filters.',
              price: '€800 - €1,400',
            },
            {
              name: 'MVP web app / Mini-SaaS',
              includes:
                'Custom business logic, user roles (Admin / Client), payments/subscriptions (Stripe), transactional email.',
              price: '€1,400 - €2,400',
            },
            {
              name: 'Simple business CRM',
              includes:
                'Digitising paper registers or Excel sheets: client records, inventory, or internal orders (CRUD).',
              price: '€1,000 - €1,800',
            },
            {
              name: 'Booking platform',
              includes:
                'Availability calendar, appointment/resource booking, slot management and automatic notifications.',
              price: '€750 - €1,300',
            },
          ],
        },
        {
          id: 'mobile',
          index: '03',
          title: 'Mobile apps',
          subtitle: 'iOS & Android',
          accent: 'var(--accent-green)',
          services: [
            {
              name: 'Showcase / content app',
              includes:
                '3-5 screens, smooth navigation, data from an existing API/site, basic notifications. Flutter or React Native.',
              price: '€600 - €1,000',
            },
            {
              name: 'Dynamic app with login & DB',
              includes:
                'Authentication, user profiles, data saved to a database (Supabase/Firebase/own backend), interactive screens.',
              price: '€1,200 - €2,200',
            },
            {
              name: 'Store publishing',
              includes:
                'iOS + Android bundle: certificates, icon, screenshots and upload to the App Store and Google Play. Developer account fees excluded.',
              price: '€120 - €180',
            },
          ],
        },
        {
          id: 'backend',
          index: '04',
          title: 'Backend',
          subtitle: 'Database & scripting',
          accent: '#f1c453',
          services: [
            {
              name: 'Database schema design',
              includes:
                'Tables, relations, foreign keys, normalisation and indexes (SQL or MongoDB).',
              price: '€150 - €300',
            },
            {
              name: 'Base REST API',
              includes:
                'Secure CRUD endpoints, input validation and clear documentation (Postman/Swagger).',
              price: '€350 - €650',
            },
            {
              name: 'Automation / bot / scraping',
              includes:
                'Telegram/Discord bots, data extraction to Excel/CSV, automation of repetitive tasks.',
              price: '€120 - €250',
            },
            {
              name: 'External API integration',
              includes:
                'Connecting two systems: form → Google Sheets/ERP, payment webhooks.',
              price: '€150 - €300',
            },
          ],
        },
        {
          id: 'retainer',
          index: '05',
          title: 'Retainer',
          subtitle: 'Maintenance & servers',
          accent: 'var(--accent-color)',
          services: [
            {
              name: 'Hosting & basic maintenance',
              includes:
                'Periodic updates, weekly backups, uptime checks for websites.',
              price: '€30 - €60 / month',
            },
            {
              name: 'App / server maintenance',
              includes:
                'Database monitoring, dependency updates, small fixes (up to 3 hours/month included).',
              price: '€90 - €150 / month',
            },
            {
              name: 'Server setup / cloud deploy',
              includes:
                'VPS (Hetzner/DigitalOcean) or cloud hosting (Render, Supabase, Vercel), domain and HTTPS SSL. One-off.',
              price: '€100 - €200',
            },
          ],
        },
      ],
    },
    contact: {
      comment: '// say hello',
      title: "Let's build something.",
      text: "I'm always open to discussing new projects, creative ideas, or opportunities to be part of your vision. My inbox is open - reach out.",
      email: 'Email',
      linkedin: 'LinkedIn',
      phone: 'Phone',
      name: 'Name',
      namePlaceholder: 'Your name',
      emailLabel: 'Email',
      emailPlaceholder: 'you@example.com',
      message: 'Message',
      messagePlaceholder: 'Tell me about your project',
      send: 'Send message',
      sending: 'Sending…',
      successTitle: 'Message sent',
      successText: "Thanks for reaching out - I'll get back to you as soon as possible.",
      sendAnother: 'Send another',
      errorGeneric: 'Something went wrong. Please try again.',
      errorNetwork: 'Failed to send message. Please try again later.',
      subject: 'New message from your portfolio!',
    },
    footer: {
      copy: '© 2026 Marcello Guida - built with React & Swift ambition.',
    },
  },

  it: {
    nav: {
      home: 'home',
      about: 'chi sono',
      experience: 'esperienza',
      skills: 'skill',
      work: 'lavori',
      pricing: 'prezzi',
      contact: 'contatti',
      cta: 'Scrivi',
      toggleMenu: 'Apri o chiudi menu',
      langLabel: 'Lingua',
    },
    hero: {
      badge: 'Disponibile per nuovi progetti',
      titleBefore: 'Esperienze',
      titleAccent: 'native',
      titleAfter: 'iOS, curate.',
      subtitle:
        'iOS developer e designer a Napoli. Apple Developer Academy. Vincitore Swift Student Challenge 2026.',
      viewWork: 'Guarda i miei lavori',
      viewPricing: 'Vedi i prezzi',
      getInTouch: 'Scrivimi',
      markers: {
        about: 'chi sono',
        experience: 'esperienza',
        skills: 'skill',
        work: 'lavori',
        pricing: 'prezzi',
        contact: 'contatti',
      },
      photoAlt: 'Marcello Guida, iOS developer',
      codeRole: 'iOS Developer & Designer',
    },
    about: {
      comment: '// chi sono',
      greeting: 'Ciao, sono Marcello  - \ncostruisco software che rispetta le persone.',
      p1: 'Sono uno studente di Informatica all’Università degli Studi di Salerno (Fisciano) e un iOS developer che affina il mestiere alla Apple Developer Academy, programma congiunto con l’Università Federico II di Napoli. Progetto e realizzo applicazioni iOS native, dal primo sketch al prodotto in store.',
      p2: 'Quello che mi tiene alla tastiera è il passaggio tra un’idea e un’app che funziona: mi piace chiuderlo con cura, attenzione a performance, accessibilità e a quelle piccole interazioni che quasi nessuno nota - ma che tutti sentono.',
      facts: [
        { label: 'Basato a', value: 'Napoli, Italia' },
        { label: 'Studi', value: 'Informatica · Fisciano (UNISA)' },
        { label: 'Academy', value: 'Apple Developer Academy · Federico II' },
        { label: 'Premio', value: 'Swift Student Challenge 2026' },
      ],
      awardHighlight: 'Vincitore Swift Student Challenge 2026',
    },
    experience: {
      comment: '// dove sono stato',
      items: [
        {
          title: 'Apple Developer Academy',
          company: 'Università Federico II × Apple',
          location: 'Napoli, Italia',
          period: 'Set 2025 - Giu 2026',
          description:
            'Programma selettivo su sviluppo iOS, product design e pensiero imprenditoriale. Costruzione e rilascio di app iOS con Swift e Xcode in sprint di team in stile Agile.',
          highlights: ['Sviluppo iOS', 'Product Design', 'Swift', 'Xcode', 'Lavoro di team'],
          marker: 'work',
          current: true,
        },
        {
          title: 'Swift Student Challenge 2026',
          company: 'Apple · WWDC26',
          location: 'Remoto',
          period: 'Feb 2026',
          description:
            'Selezionato come vincitore con un playground Swift interattivo su accessibilità e apprendimento ludico - consegnato come esperienza pronta per l’App Store.',
          highlights: ['Swift Playgrounds', 'Accessibilità', 'SwiftUI', 'Vincitore'],
          marker: 'award',
          current: false,
        },
        {
          title: 'Laurea triennale in Informatica',
          company: 'Università degli Studi di Salerno (UNISA)',
          location: 'Fisciano, Italia',
          period: '2023 - Presente',
          description:
            'Studio di algoritmi, ingegneria del software e machine learning, applicando subito quanto appreso a progetti iOS nativi e al product design.',
          highlights: ['Algoritmi', 'Ingegneria del software', 'Machine Learning', 'Database'],
          marker: 'education',
          current: false,
        },
      ],
    },
    skills: {
      comment: '// cosa uso',
    },
    projects: {
      comment: '// lavori spediti',
      viewGithub: 'Vedi GitHub',
      explore: 'Esplora progetto',
      items: [
        {
          title: 'Echoes',
          subtitle: 'Swift Student Challenge',
          description:
            'Storia interattiva su esclusione, silenzio e il coraggio di parlare - Vincitore dell’Apple Swift Student Challenge 2026. Realizzato con Swift Playgrounds per WWDC26.',
          tags: ['Swift', 'SwiftUI', 'Playgrounds', 'WWDC26'],
          link: '/echoes/index.html',
          cover: '/projects/echoes-cover.jpg',
        },
        {
          title: 'Polly',
          subtitle: 'Eco-compagno digitale',
          description:
            'Un eco-compagno digitale che aiuta a capire e ridurre l’inquinamento dei dati: pulisci la libreria foto, impara i fatti e chatta con Apple Intelligence on-device - tutto in privato.',
          tags: ['Swift', 'iOS', 'Apple Intelligence', 'Sostenibilità'],
          link: '/marcelloguida-polly/indexPolly.html',
          cover: '/projects/marcelloguida-polly-cover.jpg',
        },
        {
          title: 'SyncPoint',
          subtitle: 'Tennis & Padel',
          description:
            'Segnapunti Tennis e Padel per Apple Watch e iPhone: punteggio al polso, tabellone live, statistiche, Apple Health e partite condivise con gli avversari.',
          tags: ['Swift', 'watchOS', 'iOS', 'HealthKit'],
          link: '/syncpoint/syncpoint.html',
          cover: '/projects/syncpoint-cover.jpg',
        },
        {
          title: 'World of Fables',
          subtitle: 'Lumi',
          description:
            'Un’esperienza immersiva per iPad che trasforma le favole classiche in giochi interattivi, pensata per insegnare la sequenzialità logica ai bambini con un forte focus sull’accessibilità.',
          tags: ['Swift', 'iPadOS', 'Accessibilità', 'Game Design'],
          link: '/world-of-fables/index.html',
          cover: '/projects/world-of-fables-cover.jpg',
        },
      ],
    },
    pricing: {
      comment: '// listino chiaro, lavoro serio',
      titleBefore: 'Prezzi pensati per',
      titleAccent: 'partire forte',
      titleAfter: '.',
      lead:
        'Un listino completo e competitivo per siti, web app, mobile e backend - cifre serie, senza svendere il mestiere.',
      ratesAria: 'Tariffe base e manodopera',
      rates: [
        {
          id: 'hourly',
          label: 'Tariffa oraria',
          range: '18€ - 25€',
          unit: '/ ora',
          note: 'Ritocchi, modifiche, bug fix',
        },
        {
          id: 'day',
          label: 'Giornata (8 ore)',
          range: '120€ - 160€',
          unit: '/ giorno',
          note: 'Focus pieno su un deliverable',
        },
        {
          id: 'pack',
          label: 'Pacchetto 10 ore',
          range: '180€',
          unit: ' a scalare',
          note: 'Supporto continuo, da proporre al cliente',
        },
      ],
      categoriesAria: 'Categorie servizi',
      includesLabel: 'Cosa comprende',
      indicativeLabel: 'Prezzo indicativo',
      cta: 'Richiedi un preventivo',
      categories: [
        {
          id: 'web',
          index: '01',
          title: 'Siti Web',
          subtitle: 'Web Development',
          accent: 'var(--accent-color)',
          services: [
            {
              name: 'Landing Page / One-Page',
              includes:
                'Singola pagina promozionale o evento, responsive (smartphone/desktop), modulo contatti email, mappa, grafica moderna.',
              price: '180€ - 300€',
            },
            {
              name: 'Sito Vetrina Base (4-5 pagine)',
              includes:
                'Home, Chi Siamo, Servizi, Contatti, Privacy Policy. Realizzato su WordPress o con codice statico moderno.',
              price: '350€ - 600€',
            },
            {
              name: 'Sito Dinamico con CMS',
              includes:
                'Catalogo prodotti (senza vendita diretta), blog o area news gestibile autonomamente dal cliente con pannello admin.',
              price: '500€ - 850€',
            },
            {
              name: 'E-commerce Base',
              includes:
                'Shopify / WooCommerce. Fino a 20-30 prodotti caricati, carrello, pagamenti (Stripe/PayPal), setup spedizioni base e notifiche ordine.',
              price: '650€ - 1.100€',
            },
          ],
        },
        {
          id: 'fullstack',
          index: '02',
          title: 'Web App',
          subtitle: 'Full-Stack su misura',
          accent: 'var(--accent-secondary)',
          services: [
            {
              name: 'Dashboard / Portale Utenti Base',
              includes:
                'Login/Registrazione (JWT/Sessioni), gestione profilo, database relazionale o NoSQL, tabelle dati e filtri.',
              price: '800€ - 1.400€',
            },
            {
              name: 'MVP Web App / Mini-SaaS',
              includes:
                'Logica di business custom, ruoli utente (Admin / Cliente), integrazione pagamenti/abbonamenti (Stripe), email transazionali.',
              price: '1.400€ - 2.400€',
            },
            {
              name: 'Gestionale Aziendale Semplice',
              includes:
                'Digitalizzazione di registri o fogli Excel: anagrafica clienti, inventario magazzino o ordini interni (CRUD).',
              price: '1.000€ - 1.800€',
            },
            {
              name: 'Piattaforma di Prenotazioni',
              includes:
                'Calendario disponibilità, prenotazione appuntamenti/risorse, gestione slot e notifiche automatiche.',
              price: '750€ - 1.300€',
            },
          ],
        },
        {
          id: 'mobile',
          index: '03',
          title: 'App Mobile',
          subtitle: 'iOS & Android',
          accent: 'var(--accent-green)',
          services: [
            {
              name: 'App Vetrina / Contenuti',
              includes:
                '3-5 schermate, navigazione fluida, lettura dati da API/sito esistente, notifiche base. Flutter o React Native.',
              price: '600€ - 1.000€',
            },
            {
              name: 'App Dinamica con Login e DB',
              includes:
                'Autenticazione, profili utente, salvataggio dati (Supabase/Firebase/backend proprio), schermate interattive.',
              price: '1.200€ - 2.200€',
            },
            {
              name: 'Pubblicazione Store',
              includes:
                'Bundle iOS + Android: certificati, icona, screenshot e caricamento su App Store e Google Play. Costi account sviluppatore esclusi.',
              price: '120€ - 180€',
            },
          ],
        },
        {
          id: 'backend',
          index: '04',
          title: 'Backend',
          subtitle: 'Database & Scripting',
          accent: '#f1c453',
          services: [
            {
              name: 'Progettazione Schema Database',
              includes:
                'Tabelle, relazioni, foreign key, normalizzazione e indici (SQL o MongoDB).',
              price: '150€ - 300€',
            },
            {
              name: 'API REST Base',
              includes:
                'Endpoint sicuri CRUD, validazione input e documentazione chiara (Postman/Swagger).',
              price: '350€ - 650€',
            },
            {
              name: 'Automazione / Bot / Scraping',
              includes:
                'Bot Telegram/Discord, estrazione dati in Excel/CSV, automazione di task ripetitivi.',
              price: '120€ - 250€',
            },
            {
              name: 'Integrazione API Esterne',
              includes:
                'Collegamento tra due software: moduli → Google Sheets/gestionale, webhook pagamenti.',
              price: '150€ - 300€',
            },
          ],
        },
        {
          id: 'retainer',
          index: '05',
          title: 'Retainer',
          subtitle: 'Manutenzione & Server',
          accent: 'var(--accent-color)',
          services: [
            {
              name: 'Hosting & Manutenzione Base',
              includes:
                'Aggiornamenti periodici, backup settimanale, verifica funzionamento per siti web.',
              price: '30€ - 60€ / mese',
            },
            {
              name: 'Manutenzione Applicativa / Server',
              includes:
                'Monitoraggio database, aggiornamento dipendenze, piccoli fix (fino a 3 ore/mese incluse).',
              price: '90€ - 150€ / mese',
            },
            {
              name: 'Setup Server / Deploy Cloud',
              includes:
                'VPS (Hetzner/DigitalOcean) o hosting cloud (Render, Supabase, Vercel), dominio e SSL HTTPS. Una tantum.',
              price: '100€ - 200€',
            },
          ],
        },
      ],
    },
    contact: {
      comment: '// ciao',
      title: 'Costruiamo qualcosa.',
      text: 'Sono sempre aperto a nuovi progetti, idee creative o opportunità per entrare nella tua visione. La casella è aperta - scrivimi.',
      email: 'Email',
      linkedin: 'LinkedIn',
      phone: 'Telefono',
      name: 'Nome',
      namePlaceholder: 'Il tuo nome',
      emailLabel: 'Email',
      emailPlaceholder: 'tu@esempio.com',
      message: 'Messaggio',
      messagePlaceholder: 'Parlami del tuo progetto',
      send: 'Invia messaggio',
      sending: 'Invio…',
      successTitle: 'Messaggio inviato',
      successText: 'Grazie per aver scritto - ti rispondo il prima possibile.',
      sendAnother: 'Inviane un altro',
      errorGeneric: 'Qualcosa è andato storto. Riprova.',
      errorNetwork: 'Invio non riuscito. Riprova più tardi.',
      subject: 'Nuovo messaggio dal portfolio!',
    },
    footer: {
      copy: '© 2026 Marcello Guida - costruito con React & ambizione Swift.',
    },
  },
}
