# UniSathi: product and launch guide

## What the preview demonstrates

This is a premium product website and interactive visual concept. Rahul, status updates, timestamps, alerts, and dashboard information are illustrative. It does **not** collect locations, send messages, detect substance use, or contact guardians by itself.

## Proposed roles and access

| Role | Proposed access |
| --- | --- |
| Student | Profile, consent-aware check-in, attendance status, help/SOS, support reporting. |
| Parent/guardian | Approved attendance, arrival, exit, and institution-configured escalation updates for linked students. |
| Teacher | Class roster, attendance recording/review, classroom announcements. |
| College administrator | Configured alerts, reports, authorised case review and response coordination. |
| Campus security | Assigned emergency and safety cases only, with response status updates. |

## Proposed SOS workflow

1. A student deliberately presses the SOS control and receives a confirmation/cancel screen.
2. The platform records the request time and configured contextual information, subject to consent and policy.
3. It routes the request to the college’s authorised response contacts and campus-security queue.
4. The assigned responder acknowledges, updates the case, and follows the college’s emergency procedure.
5. A guardian alert is sent only according to the approved escalation policy.
6. The case is closed with a restricted, auditable summary.

Exact delivery time, availability and escalation recipients must be defined by the college, mobile-network conditions, the final software architecture and legal/privacy review. The current theme therefore does not promise a number of seconds for SOS delivery.

## Proposed behaviour and incident workflow

Bullying, ragging, medical, wellbeing and safety concerns should be reported by a student or authorised staff member, rather than claimed as automatic detection. A report includes category, optional details, time, location if consented, and an assigned responder. The institution verifies it, coordinates its response, and sends only the notifications permitted by its policy. Do not send behavioural allegations (for example, suspected alcohol/tobacco/gutkha use) directly to parents without an authorised human review, clear policy, an appeal path, and applicable consent/privacy safeguards.

## What makes it live

The preview is a local static demonstration. The theme becomes a live WordPress website only after it is installed on a WordPress host. A real operational platform further needs a backend, authenticated role accounts, consent and permissions, notification providers, audit logs, incident policy, security review and human response procedures.

## Installation

1. In WordPress admin, go to **Appearance → Themes → Add New → Upload Theme**.
2. Upload `unisathi-theme.zip`, install, and activate it.
3. Set the homepage to a static page using the theme’s front page.
4. Ensure the WordPress server can send mail for the contact form; production sites usually configure SMTP.

## Sharing

`unisathi-preview.html` works only on the computer where it is stored. To give a friend a clickable public link, publish the static preview to GitHub Pages, Netlify, or Cloudflare Pages. To share the actual WordPress version, deploy WordPress with this theme to a WordPress-capable host.

