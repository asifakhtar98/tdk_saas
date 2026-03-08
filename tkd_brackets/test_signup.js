const url = 'https://rxhowklmwzfwururzqon.supabase.co/auth/v1/signup';
const key = 'sb_publishable_7Ii5nmEzfL6diddK3rHHPQ_91GDOev_';

fetch(url, {
    method: 'POST',
    headers: {
        'apikey': key,
        'Content-Type': 'application/json'
    },
    body: JSON.stringify({ email: `test-${Date.now()}@example.com`, password: 'password1234' })
})
    .then(r => r.json())
    .then(console.log)
    .catch(console.error);
