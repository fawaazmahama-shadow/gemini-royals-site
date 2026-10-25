Gemini Royals - study group website

1. Keep ALL the .html files together in one folder (they link to each other).
2. Supabase: create a project, open SQL Editor, run schema.sql once.
   (Already ran an older version? Run add-features.sql, add-whatsapp.sql and add-members.sql and add-class-link.sql and add-recordings.sql instead.)
3. Open any .html file in a text editor, find the line starting "const CFG=" and paste your
   Supabase project URL and anon key. Do this in EVERY .html file (same line in each). Easy way: in VS Code press Ctrl+Shift+H, search for  const CFG={url:'',key:''}  and replace it with your own values across all files.
4. Sign up on the site with fawaazmahama@gmail.com and confirm the email. That account is the admin automatically
   (schema.sql also promotes it if it already existed). Everyone else starts as pending until you approve them.
5. Upload the whole folder to a host (Netlify, GitHub Pages, etc.).
Without step 3 the site runs in demo mode (data saved only in your browser).
