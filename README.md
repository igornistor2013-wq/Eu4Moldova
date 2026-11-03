# Dashboard cereri de suport extern

Dashboard interactiv pentru cererile din formularul oformo. Conține indicatori, grafice pe care poți da click pentru filtrare, căutare, un tabel sortabil și detaliile fiecărei cereri. Butonul **Restart** aduce datele actualizate.

> **Nu pune niciodată link-ul de export oformo (cel cu `token=`) în fișierele din acest repository.** Link-ul se păstrează doar ca secret în Cloudflare sau în browserul tău.

## Varianta online — un link cu parolă (Cloudflare Worker)

1. **Pregătește link-ul.** În oformo, generează un token nou și copiază link-ul complet de export CSV.
2. **Intră în Cloudflare.** Deschide [dash.cloudflare.com](https://dash.cloudflare.com); contul gratuit este suficient.
3. **Creează Worker-ul.** Mergi la **Workers & Pages** → **Create** și creează un Worker nou pornind de la „Hello World”.
   - Dă-i un nume, de exemplu `cereri-dashboard`, apoi apasă **Deploy**.
   - Dacă ți se cere, alege un subdomeniu `workers.dev`.
4. **Pune codul.** Apasă **Edit code**, șterge tot codul existent, lipește conținutul fișierului `worker.js` din acest folder și apasă **Deploy**.
5. **Adaugă secretele.** În Worker, mergi la **Settings** → **Variables and Secrets** → **Add**, alege tipul **Secret** și adaugă:

   | Nume | Valoare |
   |---|---|
   | `OFORMO_URL` | link-ul de export de la pasul 1 |
   | `DASHBOARD_PASSWORD` | o parolă de cel puțin 12 caractere |

   Apasă **Deploy**.
6. **Verifică și distribuie.** Deschide adresa Worker-ului (`https://cereri-dashboard.<subdomeniu>.workers.dev`) și introdu parola. Trimite colegilor link-ul, iar parola pe un canal separat.

**Întreținere**
- **Schimbi parola:** modifici secretul `DASHBOARD_PASSWORD` și apeși **Deploy**. Toți utilizatorii vor trebui să se autentifice din nou.
- **Token nou în oformo:** actualizezi secretul `OFORMO_URL`.
- **Sesiunea și deconectarea:** o sesiune durează 30 de zile. Butonul **Ieșire** deconectează dispozitivul curent.
- **Datele în browser:** în varianta online, datele nu se salvează în browserul utilizatorilor.
- **Modifici pagina:** `worker.js` conține o copie a paginii `dashboard-cereri.html`. Dacă modifici pagina, actualizează și `worker.js`.

## Varianta locală — Windows, fără cont

1. **Descarcă fișierele.** Pune fișierele din acest folder într-un folder pe calculator.
2. **Pornește serverul local.** Dă dublu-click pe `Porneste dashboard.bat`. Dashboard-ul se deschide în browser la `http://localhost:8765`.
3. **Adaugă link-ul la prima pornire.** Lipește link-ul de export în **Sursa datelor**, jos în pagină. Link-ul se păstrează doar în browserul tău.

Lasă fereastra neagră deschisă cât folosești dashboard-ul. Dacă Windows afișează „Windows protected your PC”, alege **More info** → **Run anyway**.

## Fișiere

| Fișier | Rol |
|---|---|
| `worker.js` | Varianta online: login cu parolă, pagina și preluarea datelor de pe oformo |
| `dashboard-cereri.html` | Pagina dashboard-ului |
| `Porneste dashboard.bat` | Pornește varianta locală pe Windows |
| `dashboard-server.ps1` | Serverul local folosit de `Porneste dashboard.bat` |
