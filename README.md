# Gemini Royals

Study group website: login with admin approval, timeline, online classes, recordings, resources, memories, guestbook, announcements, assignments, group chat, members directory, and a background slideshow.

Everything is in this one folder: the `.html` pages, the `.sql` database files and the logo images. The pages link to each other, so keep them together at the top level of the repository (`index.html` must be at the root).

## Setup

1. **Database:** in Supabase open **SQL Editor > New query**, paste the contents of `schema.sql` and run it (choose "Run and enable RLS" if asked).
   `schema.sql` erases all existing site data and rebuilds it. If you only need to add one feature, run the matching file instead, and each is safe to run again: `add-members.sql`, `add-features.sql`, `add-whatsapp.sql`, `add-class-link.sql`, `add-recordings.sql`, `add-backgrounds.sql`.
2. **Supabase keys:** open `config.js` (the only file you need to edit), paste your project URL and **anon** key between the quotes, and save. Keep the quotes and the comma after the URL. Never put the `service_role` key anywhere in this repository.
3. **WhatsApp group link:** it is kept in the database, not in the code, so it stays members-only. Run this once in the SQL Editor with your own link:
   `update settings set value = 'YOUR_GROUP_INVITE_LINK' where key = 'whatsapp';`
4. **Admin:** sign up on the site with `fawaazmahama@gmail.com` and confirm the email. That account becomes the admin. Everyone else stays "pending" until approved on the Admin page. Keep "Confirm email" switched on in Supabase > Authentication.
5. **Deploy:** connect the repository to Vercel, Netlify or GitHub Pages.

Without step 2 (or if `config.js` is left blank) the site runs in demo mode, and data is saved only in the visitor's browser.
