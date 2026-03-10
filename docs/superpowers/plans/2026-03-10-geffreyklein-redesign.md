# geffreyklein.com Redesign — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild geffreyklein.com as a modern, responsive medical practice website with a warm teal/sage palette, hybrid single-page + subpages structure, and elevated Weight Loss Clinic presence.

**Architecture:** Astro static site with Tailwind CSS for styling, deployed to Vercel. Astro gives us fast static pages with zero JS by default, islands for interactive components (appointment form, video player), and built-in routing for subpages. No React runtime needed for a content site.

**Tech Stack:** Astro 5, Tailwind CSS 4, TypeScript, Vercel (hosting)

**Design Spec:** `docs/superpowers/specs/2026-03-10-geffreyklein-redesign-design.md`

**Color Palette:**
| Token | Hex | Usage |
|-------|-----|-------|
| `pale-silver` | `#C6C5B9` | Section backgrounds, card fills |
| `teal` | `#62929E` | Secondary buttons, icons, accents |
| `deep-teal` | `#4A6D7C` | Primary buttons, CTAs, header |
| `dark-olive` | `#393A10` | Headings, body text |
| `charcoal` | `#475657` | Subheadings, captions |

**Key Links:**
- Google Review: `https://g.page/r/CR1ccgPImkkOEBM/review`
- Facebook Group: `https://www.facebook.com/groups/64781863202`
- YouTube Channel: `https://www.youtube.com/channel/UCFquFEcz5gwZQNVEyRGdkbg`
- IntakeQ Obesity: `https://intakeq.com/new/k3r67k`
- IntakeQ OB: `https://intakeq.com/new/vplnkm`
- IntakeQ Gyn: `https://intakeq.com/new/6nzzu9`

---

## Chunk 1: Project Setup & Layout Shell

### Task 1: Scaffold Astro Project

**Files:**
- Create: `Developer/geffreyklein-com/package.json`
- Create: `Developer/geffreyklein-com/astro.config.mjs`
- Create: `Developer/geffreyklein-com/tailwind.config.mjs`
- Create: `Developer/geffreyklein-com/tsconfig.json`
- Create: `Developer/geffreyklein-com/src/styles/global.css`

- [ ] **Step 1: Create project with Astro CLI**

```bash
cd /Users/gyndok/Developer
npm create astro@latest geffreyklein-com -- --template minimal --no-install --typescript strict
cd geffreyklein-com
```

- [ ] **Step 2: Install dependencies**

```bash
npm install
npm install @astrojs/tailwind tailwindcss
```

- [ ] **Step 3: Configure Astro with Tailwind**

Update `astro.config.mjs`:
```js
import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';

export default defineConfig({
  integrations: [tailwind()],
  site: 'https://geffreyklein.com',
});
```

- [ ] **Step 4: Configure Tailwind with color palette**

Create `tailwind.config.mjs`:
```js
/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}'],
  theme: {
    extend: {
      colors: {
        'pale-silver': '#C6C5B9',
        'teal': '#62929E',
        'deep-teal': '#4A6D7C',
        'dark-olive': '#393A10',
        'charcoal': '#475657',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
};
```

- [ ] **Step 5: Add global CSS**

Create `src/styles/global.css`:
```css
@import 'tailwindcss';

@theme {
  --color-pale-silver: #C6C5B9;
  --color-teal: #62929E;
  --color-deep-teal: #4A6D7C;
  --color-dark-olive: #393A10;
  --color-charcoal: #475657;
  --font-sans: 'Inter', system-ui, sans-serif;
}

html {
  scroll-behavior: smooth;
}

body {
  color: var(--color-dark-olive);
}
```

- [ ] **Step 6: Verify dev server starts**

```bash
npm run dev
```

Expected: Server starts on `localhost:4321`, blank page renders.

- [ ] **Step 7: Init git repo and commit**

```bash
git init
echo "node_modules/\ndist/\n.astro/\n.env" > .gitignore
git add .
git commit -m "feat: scaffold Astro project with Tailwind and color palette"
```

---

### Task 2: Base Layout & Navigation

**Files:**
- Create: `src/layouts/BaseLayout.astro`
- Create: `src/components/Header.astro`
- Create: `src/components/Footer.astro`
- Modify: `src/pages/index.astro`

- [ ] **Step 1: Create BaseLayout**

Create `src/layouts/BaseLayout.astro`:
```astro
---
interface Props {
  title: string;
  description?: string;
}

const { title, description = 'Geffrey H. Klein, MD, FACOG — Board Certified OBGYN and Obesity Medicine specialist in Clear Lake, Texas.' } = Astro.props;
---

<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="description" content={description} />
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet" />
    <title>{title}</title>
  </head>
  <body class="bg-white font-sans text-dark-olive">
    <Header />
    <main>
      <slot />
    </main>
    <Footer />
  </body>
</html>
```

Note: Import Header and Footer components at the top of the frontmatter.

- [ ] **Step 2: Create Header with sticky nav**

Create `src/components/Header.astro`:
```astro
---
const navItems = [
  { label: 'About', href: '/#about' },
  { label: 'Services', href: '/#services' },
  { label: 'Weight Loss', href: '/weight-loss' },
  { label: 'Videos', href: '/videos' },
  { label: 'Reviews', href: '/#reviews' },
  { label: 'Contact', href: '/#contact' },
];
---

<header class="sticky top-0 z-50 bg-white/95 backdrop-blur-sm border-b border-pale-silver">
  <nav class="container mx-auto px-4 py-4 flex items-center justify-between">
    <a href="/" class="text-xl font-bold text-deep-teal">
      Dr. Klein
    </a>

    <!-- Desktop nav -->
    <div class="hidden md:flex items-center gap-6">
      {navItems.map((item) => (
        <a href={item.href} class="text-sm font-medium text-charcoal hover:text-deep-teal transition-colors">
          {item.label}
        </a>
      ))}
      <a href="/appointment" class="bg-deep-teal text-white px-5 py-2 rounded-lg text-sm font-semibold hover:bg-teal transition-colors">
        Book Appointment
      </a>
    </div>

    <!-- Mobile menu button -->
    <button id="mobile-menu-btn" class="md:hidden text-charcoal" aria-label="Open menu">
      <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
      </svg>
    </button>
  </nav>

  <!-- Mobile menu -->
  <div id="mobile-menu" class="hidden md:hidden border-t border-pale-silver bg-white px-4 pb-4">
    {navItems.map((item) => (
      <a href={item.href} class="block py-2 text-sm font-medium text-charcoal hover:text-deep-teal">
        {item.label}
      </a>
    ))}
    <a href="/appointment" class="block mt-2 bg-deep-teal text-white px-5 py-2 rounded-lg text-sm font-semibold text-center">
      Book Appointment
    </a>
  </div>
</header>

<script>
  const btn = document.getElementById('mobile-menu-btn');
  const menu = document.getElementById('mobile-menu');
  btn?.addEventListener('click', () => menu?.classList.toggle('hidden'));
</script>
```

- [ ] **Step 3: Create Footer**

Create `src/components/Footer.astro`:
```astro
<footer class="bg-dark-olive text-pale-silver py-12">
  <div class="container mx-auto px-4">
    <div class="grid md:grid-cols-3 gap-8">
      <div>
        <h3 class="text-white font-bold text-lg mb-3">Geffrey H. Klein, MD, FACOG</h3>
        <p class="text-sm">Women's Specialists of Clear Lake</p>
        <p class="text-sm">400 Medical Center Blvd, Suite 300</p>
        <p class="text-sm">Webster, TX 77598</p>
      </div>
      <div>
        <h3 class="text-white font-bold text-lg mb-3">Contact</h3>
        <p class="text-sm">Phone: <a href="tel:2815570300" class="hover:text-white">(281) 557-0300</a></p>
        <p class="text-sm">Fax: (281) 557-3301</p>
        <p class="text-sm">Languages: English, Spanish</p>
      </div>
      <div>
        <h3 class="text-white font-bold text-lg mb-3">Hours</h3>
        <p class="text-sm">Mon–Thu: 8:30 AM–11:00 AM, 1:30 PM–4:00 PM</p>
        <p class="text-sm">Fri: 8:30 AM–11:00 AM</p>
        <p class="text-sm">Sat–Sun: Closed</p>
      </div>
    </div>
    <div class="border-t border-charcoal mt-8 pt-8 text-sm text-center">
      &copy; {new Date().getFullYear()} Geffrey H. Klein, MD. All rights reserved.
    </div>
  </div>
</footer>
```

- [ ] **Step 4: Update index.astro to use layout**

Replace `src/pages/index.astro`:
```astro
---
import BaseLayout from '../layouts/BaseLayout.astro';
---

<BaseLayout title="Dr. Geffrey Klein — OBGYN & Obesity Medicine | Webster, TX">
  <p class="p-8 text-center text-charcoal">Site coming together...</p>
</BaseLayout>
```

- [ ] **Step 5: Verify layout renders correctly**

```bash
npm run dev
```

Expected: Page shows sticky header with nav links, placeholder content, and footer. Mobile menu toggle works.

- [ ] **Step 6: Commit**

```bash
git add .
git commit -m "feat: add base layout with sticky header and footer"
```

---

## Chunk 2: Homepage Sections

### Task 3: Hero Section

**Files:**
- Create: `src/components/Hero.astro`
- Modify: `src/pages/index.astro`
- Download: Doctor headshot to `public/images/dr-klein.jpg`

- [ ] **Step 1: Download headshot image**

```bash
curl -o public/images/dr-klein.jpg "https://s3-media0.fl.yelpcdn.com/bphoto/D7-Ce2qH5wJA4PJIAoW-Jw/348s.jpg"
```

Note: This is a temporary image. Replace with a higher-resolution professional headshot later.

- [ ] **Step 2: Create Hero component**

Create `src/components/Hero.astro`:
```astro
<section class="relative min-h-[500px] flex items-center overflow-hidden bg-gradient-to-br from-white to-pale-silver/50">
  <div class="container mx-auto px-4 py-16">
    <div class="flex flex-col md:flex-row items-center gap-12">
      <!-- Text side -->
      <div class="flex-1 max-w-xl">
        <p class="text-sm font-semibold tracking-widest text-teal uppercase mb-3">
          Women's Health & Weight Management
        </p>
        <h1 class="text-4xl md:text-5xl font-bold text-dark-olive leading-tight mb-4">
          Geffrey H. Klein, MD, FACOG
        </h1>
        <p class="text-lg text-charcoal mb-1">Board Certified Obstetrics & Gynecology</p>
        <p class="text-lg text-charcoal mb-4">Board Certified Obesity Medicine</p>
        <p class="text-teal italic text-lg mb-8">
          "Taking care of women through all stages of life"
        </p>
        <div class="flex flex-col sm:flex-row gap-3">
          <a href="/appointment" class="bg-deep-teal text-white px-8 py-3 rounded-lg font-semibold text-center hover:bg-teal transition-colors">
            Book Appointment
          </a>
          <a href="/weight-loss" class="border-2 border-teal text-teal px-8 py-3 rounded-lg font-semibold text-center hover:bg-teal hover:text-white transition-colors">
            Weight Loss Clinic
          </a>
        </div>
      </div>

      <!-- Photo side -->
      <div class="flex-shrink-0">
        <div class="w-64 h-80 md:w-80 md:h-96 rounded-2xl overflow-hidden shadow-xl">
          <img
            src="/images/dr-klein.jpg"
            alt="Dr. Geffrey H. Klein"
            class="w-full h-full object-cover"
          />
        </div>
      </div>
    </div>
  </div>
</section>
```

- [ ] **Step 3: Add Hero to index.astro**

Update `src/pages/index.astro`:
```astro
---
import BaseLayout from '../layouts/BaseLayout.astro';
import Hero from '../components/Hero.astro';
---

<BaseLayout title="Dr. Geffrey Klein — OBGYN & Obesity Medicine | Webster, TX">
  <Hero />
</BaseLayout>
```

- [ ] **Step 4: Verify hero renders**

```bash
npm run dev
```

Expected: Split hero with text left, photo right. Two CTA buttons. Responsive on mobile (stacks vertically).

- [ ] **Step 5: Commit**

```bash
git add .
git commit -m "feat: add split hero section with headshot and dual CTAs"
```

---

### Task 4: About Section

**Files:**
- Create: `src/components/About.astro`
- Modify: `src/pages/index.astro`

- [ ] **Step 1: Create About component**

Create `src/components/About.astro`:
```astro
<section id="about" class="py-20 bg-white">
  <div class="container mx-auto px-4">
    <div class="max-w-3xl mx-auto">
      <h2 class="text-3xl font-bold text-dark-olive mb-8 text-center">About Dr. Klein</h2>

      <div class="prose prose-lg max-w-none text-charcoal mb-10">
        <p>
          Geffrey Klein, MD, FACOG is a highly qualified obstetrician and gynecologist with years of experience.
          He received his medical degree and residency in OBGYN from <strong>Baylor College of Medicine</strong>,
          where he served as OB/GYN Administrative Chief Resident.
        </p>
        <p>
          Dr. Klein graduated with honors from the <strong>University of Texas at Austin</strong> with a Bachelor of Arts
          in Biology. He is Board Certified with the American Board of Obstetrics and Gynecology, a Fellow of
          the American College of Obstetricians and Gynecologists, and Board Certified with the American Board of Obesity Medicine.
        </p>
        <p class="text-teal italic text-xl mt-8 text-center">
          "Taking care of women through all stages of life."
        </p>
      </div>

      <!-- Credential badges -->
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
        {[
          { title: 'Board Certified', subtitle: 'Obstetrics & Gynecology' },
          { title: 'FACOG', subtitle: 'Fellow, American College of OB/GYN' },
          { title: 'Board Certified', subtitle: 'Obesity Medicine' },
          { title: 'Chief Resident', subtitle: 'Baylor College of Medicine' },
        ].map((badge) => (
          <div class="bg-pale-silver/40 rounded-xl p-4 text-center">
            <p class="font-bold text-deep-teal text-sm">{badge.title}</p>
            <p class="text-xs text-charcoal mt-1">{badge.subtitle}</p>
          </div>
        ))}
      </div>
    </div>
  </div>
</section>
```

- [ ] **Step 2: Add About to index.astro**

Add import and `<About />` after `<Hero />`.

- [ ] **Step 3: Verify and commit**

```bash
npm run dev
git add . && git commit -m "feat: add about section with credential badges"
```

---

### Task 5: Services Card Grid

**Files:**
- Create: `src/components/Services.astro`
- Modify: `src/pages/index.astro`

- [ ] **Step 1: Create Services component**

Create `src/components/Services.astro`:
```astro
---
const services = [
  {
    title: 'Obstetric Care',
    description: 'Prenatal care, high-risk pregnancies, vaginal delivery, C-section, postpartum care.',
    icon: '🤰',
    featured: false,
  },
  {
    title: 'Gynecologic Surgery',
    description: 'Robotic assisted surgery, hysterectomy, endometrial ablation, tubal ligation.',
    icon: '⚕️',
    featured: false,
  },
  {
    title: "Women's Health",
    description: 'Annual exams, pap smears, mammography screening, hormone replacement, menopause care.',
    icon: '❤️',
    featured: false,
  },
  {
    title: 'Family Planning',
    description: 'Birth control, IUD placement/removal, contraceptive implants, infertility evaluation.',
    icon: '👨‍👩‍👧',
    featured: false,
  },
  {
    title: 'Weight Loss Clinic',
    description: 'Board certified obesity medicine. Personalized weight management programs and anti-obesity medications.',
    icon: '⚖️',
    href: '/weight-loss',
    featured: true,
  },
  {
    title: 'Specialized Treatments',
    description: 'Endometriosis, uterine fibroids, cervical dysplasia, urinary incontinence, STD testing.',
    icon: '🩺',
    featured: false,
  },
];
---

<section id="services" class="py-20 bg-pale-silver/30">
  <div class="container mx-auto px-4">
    <h2 class="text-3xl font-bold text-dark-olive mb-4 text-center">Services & Procedures</h2>
    <p class="text-charcoal text-center mb-12 max-w-2xl mx-auto">
      Comprehensive obstetric and gynecologic care with expertise in robotic surgery, high-risk pregnancies, and weight management.
    </p>

    <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-6 max-w-5xl mx-auto">
      {services.map((service) => (
        <div class={`rounded-2xl p-6 transition-shadow hover:shadow-lg ${
          service.featured
            ? 'bg-gradient-to-br from-teal to-deep-teal text-white'
            : 'bg-white border border-pale-silver'
        }`}>
          <div class="text-3xl mb-3">{service.icon}</div>
          <h3 class={`text-lg font-bold mb-2 ${service.featured ? 'text-white' : 'text-dark-olive'}`}>
            {service.title}
          </h3>
          <p class={`text-sm ${service.featured ? 'text-white/80' : 'text-charcoal'}`}>
            {service.description}
          </p>
          {service.href && (
            <a href={service.href} class="inline-block mt-4 text-sm font-semibold text-white underline underline-offset-4">
              Learn More →
            </a>
          )}
        </div>
      ))}
    </div>
  </div>
</section>
```

- [ ] **Step 2: Add Services to index.astro**

Add import and `<Services />` after `<About />`.

- [ ] **Step 3: Verify and commit**

```bash
npm run dev
git add . && git commit -m "feat: add services card grid with featured weight loss clinic"
```

---

### Task 6: Reviews Section

**Files:**
- Create: `src/components/Reviews.astro`
- Modify: `src/pages/index.astro`

- [ ] **Step 1: Create Reviews component**

Create `src/components/Reviews.astro`:
```astro
---
const reviews = [
  {
    name: 'Sarah M.',
    time: '2 months ago',
    text: 'Dr. Klein is an exceptional physician who truly cares about his patients. His expertise in both OBGYN and obesity medicine is outstanding.',
  },
  {
    name: 'Jennifer L.',
    time: '3 months ago',
    text: "The best doctor I've ever had! The staff is wonderful and Dr. Klein takes time to listen and answer all questions.",
  },
  {
    name: 'Maria R.',
    time: '4 months ago',
    text: 'Highly recommend Dr. Klein and his team. Professional, compassionate, and knowledgeable. The office is always clean and welcoming.',
  },
  {
    name: 'Amanda T.',
    time: '5 months ago',
    text: "Dr. Klein helped me through my pregnancy journey with exceptional care. I couldn't have asked for a better doctor.",
  },
];
---

<section id="reviews" class="py-20 bg-pale-silver/40">
  <div class="container mx-auto px-4 text-center">
    <div class="mb-8">
      <span class="text-5xl font-bold text-dark-olive">4.8</span>
      <div class="text-teal text-2xl mt-1">★★★★★</div>
      <p class="text-charcoal text-sm mt-2">Based on 243 Google reviews</p>
    </div>

    <div class="grid md:grid-cols-2 lg:grid-cols-4 gap-4 max-w-5xl mx-auto mb-10">
      {reviews.map((review) => (
        <div class="bg-white rounded-xl p-5 text-left shadow-sm">
          <div class="flex items-center gap-2 mb-3">
            <div class="w-8 h-8 bg-teal/20 rounded-full flex items-center justify-center text-deep-teal font-bold text-sm">
              {review.name[0]}
            </div>
            <div>
              <p class="font-semibold text-dark-olive text-sm">{review.name}</p>
              <p class="text-xs text-charcoal">{review.time}</p>
            </div>
          </div>
          <p class="text-sm text-charcoal">{review.text}</p>
        </div>
      ))}
    </div>

    <div class="flex flex-col sm:flex-row gap-3 justify-center">
      <a
        href="https://g.page/r/CR1ccgPImkkOEBM/review"
        target="_blank"
        rel="noopener noreferrer"
        class="bg-deep-teal text-white px-6 py-3 rounded-lg font-semibold hover:bg-teal transition-colors"
      >
        Leave a Review →
      </a>
      <a
        href="https://www.google.com/search?q=geffrey+klein"
        target="_blank"
        rel="noopener noreferrer"
        class="border border-charcoal text-charcoal px-6 py-3 rounded-lg font-semibold hover:bg-charcoal hover:text-white transition-colors"
      >
        Read All Reviews
      </a>
    </div>
  </div>
</section>
```

- [ ] **Step 2: Add Reviews to index.astro**

Add import and `<Reviews />` after `<Services />`.

- [ ] **Step 3: Verify and commit**

```bash
npm run dev
git add . && git commit -m "feat: add reviews section with Google review link"
```

---

### Task 7: Contact Section

**Files:**
- Create: `src/components/Contact.astro`
- Modify: `src/pages/index.astro`

- [ ] **Step 1: Create Contact component**

Create `src/components/Contact.astro`:
```astro
<section id="contact" class="py-20 bg-white">
  <div class="container mx-auto px-4">
    <h2 class="text-3xl font-bold text-dark-olive mb-12 text-center">Contact & Location</h2>

    <div class="grid md:grid-cols-2 gap-12 max-w-5xl mx-auto">
      <!-- Info side -->
      <div>
        <h3 class="text-xl font-bold text-dark-olive mb-4">Women's Specialists of Clear Lake</h3>

        <div class="space-y-4 text-charcoal">
          <div>
            <p class="font-semibold text-dark-olive text-sm uppercase tracking-wide mb-1">Address</p>
            <a
              href="https://www.google.com/maps/search/?api=1&query=400+Medical+Center+Blvd+Suite+300+Webster+TX+77598"
              target="_blank"
              rel="noopener noreferrer"
              class="text-deep-teal hover:underline"
            >
              400 Medical Center Blvd, Suite 300<br />Webster, TX 77598
            </a>
          </div>

          <div>
            <p class="font-semibold text-dark-olive text-sm uppercase tracking-wide mb-1">Phone</p>
            <a href="tel:2815570300" class="text-deep-teal hover:underline">(281) 557-0300</a>
            <p class="text-xs text-charcoal mt-1">*Please call if you are a self-pay patient</p>
          </div>

          <div>
            <p class="font-semibold text-dark-olive text-sm uppercase tracking-wide mb-1">Fax</p>
            <p>(281) 557-3301</p>
          </div>

          <div>
            <p class="font-semibold text-dark-olive text-sm uppercase tracking-wide mb-1">Languages</p>
            <p>English, Spanish</p>
          </div>

          <div>
            <p class="font-semibold text-dark-olive text-sm uppercase tracking-wide mb-1">Office Hours</p>
            <div class="text-sm space-y-1">
              <p>Mon–Thu: 8:30 AM – 11:00 AM, 1:30 PM – 4:00 PM</p>
              <p>Fri: 8:30 AM – 11:00 AM</p>
              <p>Sat–Sun: Closed</p>
            </div>
          </div>
        </div>

        <div class="mt-8">
          <p class="font-semibold text-dark-olive text-sm uppercase tracking-wide mb-3">New Patient Forms</p>
          <div class="flex flex-col gap-2">
            <a href="https://intakeq.com/new/k3r67k" target="_blank" rel="noopener noreferrer" class="text-sm bg-teal/10 text-deep-teal px-4 py-2 rounded-lg hover:bg-teal/20 transition-colors font-medium">
              Obesity Clinic Intake Form →
            </a>
            <a href="https://intakeq.com/new/vplnkm" target="_blank" rel="noopener noreferrer" class="text-sm bg-teal/10 text-deep-teal px-4 py-2 rounded-lg hover:bg-teal/20 transition-colors font-medium">
              New Obstetrical Patient →
            </a>
            <a href="https://intakeq.com/new/6nzzu9" target="_blank" rel="noopener noreferrer" class="text-sm bg-teal/10 text-deep-teal px-4 py-2 rounded-lg hover:bg-teal/20 transition-colors font-medium">
              New Gyn Patient →
            </a>
          </div>
        </div>
      </div>

      <!-- Map side -->
      <div>
        <div class="rounded-2xl overflow-hidden shadow-md h-80 md:h-full min-h-[320px]">
          <iframe
            src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3471.0!2d-95.12!3d29.55!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x0%3A0x0!2zMjnCsDMzJzAuMCJOIDk1wrAwNycxMi4wIlc!5e0!3m2!1sen!2sus!4v1234567890"
            width="100%"
            height="100%"
            style="border:0"
            allowfullscreen=""
            loading="lazy"
            referrerpolicy="no-referrer-when-downgrade"
            title="Office Location"
          ></iframe>
        </div>
      </div>
    </div>
  </div>
</section>
```

Note: The Google Maps embed URL will need to be updated with the actual embed URL for the office location. Search Google Maps for "400 Medical Center Blvd Suite 300 Webster TX 77598", click Share → Embed, and copy the iframe src.

- [ ] **Step 2: Add Contact to index.astro**

Add import and `<Contact />` after `<Reviews />`.

- [ ] **Step 3: Verify and commit**

```bash
npm run dev
git add . && git commit -m "feat: add contact section with map, hours, and intake form links"
```

---

## Chunk 3: Subpages

### Task 8: Weight Loss Clinic Page

**Files:**
- Create: `src/pages/weight-loss.astro`

- [ ] **Step 1: Create weight loss page**

Create `src/pages/weight-loss.astro`:
```astro
---
import BaseLayout from '../layouts/BaseLayout.astro';
---

<BaseLayout
  title="Weight Loss Clinic — Dr. Geffrey Klein | Webster, TX"
  description="Board certified obesity medicine specialist offering personalized weight management programs and anti-obesity medications in Clear Lake, Texas."
>
  <!-- Hero -->
  <section class="bg-gradient-to-br from-teal to-deep-teal text-white py-20">
    <div class="container mx-auto px-4 max-w-3xl text-center">
      <h1 class="text-4xl md:text-5xl font-bold mb-4">Weight Loss Clinic</h1>
      <p class="text-xl text-white/80 mb-2">Board Certified Obesity Medicine</p>
      <p class="text-lg text-white/70">Personalized programs to help you achieve your health goals</p>
    </div>
  </section>

  <!-- Video -->
  <section class="py-16 bg-white">
    <div class="container mx-auto px-4 max-w-3xl">
      <h2 class="text-2xl font-bold text-dark-olive mb-6 text-center">Welcome to the Weight Loss Clinic</h2>
      <div class="aspect-video rounded-2xl overflow-hidden shadow-lg">
        <iframe
          src="https://www.youtube.com/embed/L7BjNZTAF_M"
          title="Welcome to the Weight Loss Clinic"
          width="100%"
          height="100%"
          frameborder="0"
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
          allowfullscreen
        ></iframe>
      </div>
    </div>
  </section>

  <!-- About the program -->
  <section class="py-16 bg-pale-silver/30">
    <div class="container mx-auto px-4 max-w-3xl">
      <h2 class="text-2xl font-bold text-dark-olive mb-6">Our Approach</h2>
      <div class="prose prose-lg text-charcoal max-w-none">
        <p>
          Dr. Klein is Board Certified with the American Board of Obesity Medicine and takes a comprehensive,
          evidence-based approach to weight management. Treatment plans are personalized to each patient's
          unique health profile and goals.
        </p>
        <p>
          Anti-obesity medications, including GLP-1 receptor agonists, may be prescribed as part of your
          individualized treatment plan to help you achieve sustainable results.
        </p>
      </div>
    </div>
  </section>

  <!-- CTA -->
  <section class="py-16 bg-white">
    <div class="container mx-auto px-4 max-w-xl text-center">
      <h2 class="text-2xl font-bold text-dark-olive mb-4">Ready to Get Started?</h2>
      <p class="text-charcoal mb-8">Fill out the obesity clinic intake form and our staff will contact you to schedule your first appointment.</p>
      <div class="flex flex-col sm:flex-row gap-3 justify-center">
        <a
          href="https://intakeq.com/new/k3r67k"
          target="_blank"
          rel="noopener noreferrer"
          class="bg-deep-teal text-white px-8 py-3 rounded-lg font-semibold hover:bg-teal transition-colors"
        >
          Obesity Clinic Intake Form
        </a>
        <a href="tel:2815570300" class="border-2 border-teal text-teal px-8 py-3 rounded-lg font-semibold hover:bg-teal hover:text-white transition-colors">
          Call (281) 557-0300
        </a>
      </div>
    </div>
  </section>
</BaseLayout>
```

- [ ] **Step 2: Verify page at /weight-loss**

```bash
npm run dev
# Visit localhost:4321/weight-loss
```

Expected: Teal gradient hero, YouTube video embed, approach description, CTA with intake form link.

- [ ] **Step 3: Commit**

```bash
git add . && git commit -m "feat: add dedicated weight loss clinic subpage"
```

---

### Task 9: Patient Education Videos Page

**Files:**
- Create: `src/pages/videos.astro`

- [ ] **Step 1: Create videos page**

Create `src/pages/videos.astro`:
```astro
---
import BaseLayout from '../layouts/BaseLayout.astro';

const videos = [
  { id: 'L7BjNZTAF_M', title: 'Welcome to the Weight Loss Clinic', category: 'Weight Loss' },
  { id: 'SBl8frE_v5A', title: 'Estrogen Therapy', category: "Women's Health" },
  { id: 'SoH9GtZOkYE', title: 'VBAC: Your Choices', category: "Women's Health" },
  { id: '_R6ox9jwlUg', title: 'Bilateral Salpingectomy', category: 'Surgical Procedures' },
  { id: 'ZVkVVOMZzdQ', title: 'Understanding NovaSure', category: 'Surgical Procedures' },
  { id: 'zohfFNMBBFU', title: 'Da Vinci Hysterectomy', category: 'Surgical Procedures' },
  { id: 'ezpZI5PwAts', title: 'Demystifying the LEEP', category: 'Surgical Procedures' },
];

const categories = [...new Set(videos.map(v => v.category))];
---

<BaseLayout
  title="Patient Education Videos — Dr. Geffrey Klein"
  description="Educational videos about women's health, surgical procedures, and weight management from Dr. Geffrey Klein."
>
  <section class="py-20 bg-white">
    <div class="container mx-auto px-4">
      <h1 class="text-4xl font-bold text-dark-olive mb-4 text-center">Patient Education Videos</h1>
      <p class="text-charcoal text-center mb-12 max-w-2xl mx-auto">
        Educational resources to help you understand your care
      </p>

      {categories.map((category) => (
        <div class="mb-12">
          <h2 class="text-2xl font-bold text-dark-olive mb-6">{category}</h2>
          <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {videos.filter(v => v.category === category).map((video) => (
              <a
                href={`https://www.youtube.com/watch?v=${video.id}`}
                target="_blank"
                rel="noopener noreferrer"
                class="group block bg-white border border-pale-silver rounded-xl overflow-hidden hover:shadow-lg transition-shadow"
              >
                <div class="aspect-video bg-charcoal/10 relative">
                  <img
                    src={`https://img.youtube.com/vi/${video.id}/mqdefault.jpg`}
                    alt={video.title}
                    class="w-full h-full object-cover"
                    loading="lazy"
                  />
                  <div class="absolute inset-0 flex items-center justify-center bg-black/20 group-hover:bg-black/30 transition-colors">
                    <div class="w-12 h-12 bg-white/90 rounded-full flex items-center justify-center">
                      <svg class="w-5 h-5 text-deep-teal ml-0.5" fill="currentColor" viewBox="0 0 20 20">
                        <path d="M6.3 2.84A1.5 1.5 0 004 4.11v11.78a1.5 1.5 0 002.3 1.27l9.344-5.891a1.5 1.5 0 000-2.538L6.3 2.84z" />
                      </svg>
                    </div>
                  </div>
                </div>
                <div class="p-4">
                  <h3 class="font-semibold text-dark-olive group-hover:text-deep-teal transition-colors">{video.title}</h3>
                </div>
              </a>
            ))}
          </div>
        </div>
      ))}

      <div class="text-center mt-8">
        <a
          href="https://www.youtube.com/channel/UCFquFEcz5gwZQNVEyRGdkbg"
          target="_blank"
          rel="noopener noreferrer"
          class="text-deep-teal font-semibold hover:underline"
        >
          View All Videos on YouTube →
        </a>
      </div>
    </div>
  </section>
</BaseLayout>
```

- [ ] **Step 2: Verify page at /videos**

```bash
npm run dev
# Visit localhost:4321/videos
```

Expected: Clean grid of video thumbnails grouped by category. Click opens YouTube.

- [ ] **Step 3: Commit**

```bash
git add . && git commit -m "feat: add patient education videos page with thumbnail grid"
```

---

### Task 10: Appointment Request Page

**Files:**
- Create: `src/pages/appointment.astro`

- [ ] **Step 1: Create appointment page**

Create `src/pages/appointment.astro`:
```astro
---
import BaseLayout from '../layouts/BaseLayout.astro';
---

<BaseLayout
  title="Request an Appointment — Dr. Geffrey Klein"
  description="Request an appointment with Dr. Geffrey Klein, OBGYN and obesity medicine specialist in Webster, TX."
>
  <section class="py-20 bg-white">
    <div class="container mx-auto px-4 max-w-2xl">
      <h1 class="text-4xl font-bold text-dark-olive mb-4 text-center">Request an Appointment</h1>
      <p class="text-charcoal text-center mb-8">
        Fill out the form below and we'll contact you to schedule your appointment.
      </p>

      <!-- New patient forms -->
      <div class="bg-pale-silver/30 rounded-2xl p-6 mb-10">
        <h2 class="text-lg font-bold text-dark-olive mb-3">New Patient? Start Here</h2>
        <p class="text-sm text-charcoal mb-4">Please fill out the appropriate intake form:</p>
        <div class="flex flex-col gap-2">
          <a href="https://intakeq.com/new/k3r67k" target="_blank" rel="noopener noreferrer" class="bg-gradient-to-r from-teal to-deep-teal text-white px-5 py-3 rounded-lg font-semibold text-center hover:opacity-90 transition-opacity">
            Obesity Clinic Intake Form
          </a>
          <a href="https://intakeq.com/new/vplnkm" target="_blank" rel="noopener noreferrer" class="bg-deep-teal text-white px-5 py-3 rounded-lg font-semibold text-center hover:bg-teal transition-colors">
            New Obstetrical Patient
          </a>
          <a href="https://intakeq.com/new/6nzzu9" target="_blank" rel="noopener noreferrer" class="bg-deep-teal text-white px-5 py-3 rounded-lg font-semibold text-center hover:bg-teal transition-colors">
            New Gyn Patient
          </a>
        </div>
      </div>

      <!-- General appointment request form -->
      <h2 class="text-lg font-bold text-dark-olive mb-4">Or Request a Callback</h2>
      <form class="space-y-4" action="#" method="POST">
        <div class="grid grid-cols-2 gap-4">
          <div>
            <label for="patient-type" class="block text-sm font-medium text-dark-olive mb-1">Patient Type</label>
            <select id="patient-type" name="patient-type" class="w-full border border-pale-silver rounded-lg px-3 py-2 text-charcoal focus:outline-none focus:ring-2 focus:ring-teal">
              <option>New Patient</option>
              <option>Existing Patient</option>
            </select>
          </div>
          <div>
            <label for="name" class="block text-sm font-medium text-dark-olive mb-1">Full Name *</label>
            <input id="name" name="name" type="text" required class="w-full border border-pale-silver rounded-lg px-3 py-2 text-charcoal focus:outline-none focus:ring-2 focus:ring-teal" />
          </div>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div>
            <label for="email" class="block text-sm font-medium text-dark-olive mb-1">Email *</label>
            <input id="email" name="email" type="email" required class="w-full border border-pale-silver rounded-lg px-3 py-2 text-charcoal focus:outline-none focus:ring-2 focus:ring-teal" />
          </div>
          <div>
            <label for="phone" class="block text-sm font-medium text-dark-olive mb-1">Phone Number *</label>
            <input id="phone" name="phone" type="tel" required class="w-full border border-pale-silver rounded-lg px-3 py-2 text-charcoal focus:outline-none focus:ring-2 focus:ring-teal" />
          </div>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div>
            <label for="date" class="block text-sm font-medium text-dark-olive mb-1">Preferred Date *</label>
            <input id="date" name="date" type="date" required class="w-full border border-pale-silver rounded-lg px-3 py-2 text-charcoal focus:outline-none focus:ring-2 focus:ring-teal" />
          </div>
          <div>
            <label for="time" class="block text-sm font-medium text-dark-olive mb-1">Preferred Time *</label>
            <input id="time" name="time" type="time" required class="w-full border border-pale-silver rounded-lg px-3 py-2 text-charcoal focus:outline-none focus:ring-2 focus:ring-teal" />
          </div>
        </div>

        <div>
          <label for="reason" class="block text-sm font-medium text-dark-olive mb-1">Reason for Visit *</label>
          <textarea id="reason" name="reason" rows="3" required class="w-full border border-pale-silver rounded-lg px-3 py-2 text-charcoal focus:outline-none focus:ring-2 focus:ring-teal"></textarea>
        </div>

        <button type="submit" class="w-full bg-deep-teal text-white py-3 rounded-lg font-semibold hover:bg-teal transition-colors">
          Submit Request
        </button>
      </form>

      <p class="text-xs text-charcoal mt-4 text-center">
        For urgent matters, please call <a href="tel:2815570300" class="text-deep-teal hover:underline">(281) 557-0300</a>
      </p>
    </div>
  </section>
</BaseLayout>
```

Note: The form action needs to be connected to a backend (email service, Formspree, Netlify Forms, etc.) during deployment. For now it's a static form.

- [ ] **Step 2: Verify page at /appointment**

```bash
npm run dev
# Visit localhost:4321/appointment
```

Expected: Intake form links at top, callback request form below. All form fields render and are interactive.

- [ ] **Step 3: Commit**

```bash
git add . && git commit -m "feat: add appointment request page with intake form links"
```

---

## Chunk 4: Polish & Deploy

### Task 11: SEO & Meta Tags

**Files:**
- Modify: `src/layouts/BaseLayout.astro`
- Create: `public/favicon.svg`

- [ ] **Step 1: Add comprehensive meta tags to BaseLayout**

Add Open Graph and Twitter meta tags to the `<head>` of `BaseLayout.astro`:

```html
<meta property="og:title" content={title} />
<meta property="og:description" content={description} />
<meta property="og:type" content="website" />
<meta property="og:url" content="https://geffreyklein.com" />
<meta property="og:image" content="https://geffreyklein.com/images/dr-klein.jpg" />
<meta name="twitter:card" content="summary" />
<link rel="icon" type="image/svg+xml" href="/favicon.svg" />
<link rel="canonical" href={`https://geffreyklein.com${Astro.url.pathname}`} />
```

- [ ] **Step 2: Create a simple favicon**

Create `public/favicon.svg`:
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <rect width="32" height="32" rx="6" fill="#4A6D7C"/>
  <text x="16" y="22" font-family="Arial" font-size="18" font-weight="bold" fill="white" text-anchor="middle">K</text>
</svg>
```

- [ ] **Step 3: Commit**

```bash
git add . && git commit -m "feat: add SEO meta tags and favicon"
```

---

### Task 12: Final Build & Verify

**Files:** None new — verification only.

- [ ] **Step 1: Run production build**

```bash
npm run build
```

Expected: Build completes without errors. Output in `dist/` directory.

- [ ] **Step 2: Preview production build**

```bash
npm run preview
```

Expected: All pages load correctly at the preview URL. Check:
- Homepage: hero, about, services, reviews, contact
- /weight-loss: video, content, CTA
- /videos: thumbnail grid by category
- /appointment: forms and links
- Navigation works across all pages
- Mobile responsive (resize browser)

- [ ] **Step 3: Commit any fixes**

```bash
git add . && git commit -m "chore: final build verification and fixes"
```

---

### Task 13: Deploy to Vercel

**Files:**
- May create: `vercel.json` (if needed)

- [ ] **Step 1: Create GitHub repo**

```bash
gh repo create geffreyklein-com --public --source=. --remote=origin --push
```

- [ ] **Step 2: Deploy to Vercel**

```bash
npx vercel --prod
```

Follow prompts to link to the Vercel project. Astro is auto-detected.

- [ ] **Step 3: Configure custom domain**

In Vercel dashboard, add `geffreyklein.com` as a custom domain. Update DNS records as instructed by Vercel (either A record to `76.76.21.21` or CNAME to `cname.vercel-dns.com`).

- [ ] **Step 4: Verify live site**

Visit `https://geffreyklein.com` and check all pages, links, and responsive behavior.

- [ ] **Step 5: Final commit**

```bash
git add . && git commit -m "chore: deploy to Vercel"
git push
```
