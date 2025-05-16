# Begonnen 13.05.2025

<h2><strong>Aufgaben:</strong></h2>

<strong>/events/<mode></strong>
get_Events (alle datenbank events raus suchen) 🆗
new_Event (neues Event anlegen) 🆗
give_like (like zum event hinzufügen) 🆗
get_likes (likes abrufen) 🆗
delete_Event (event löschen) 🆗

<strong>/admin/<mode></strong>
login/register 🆗


<h2><strong>Info:</strong></h2>
→ erreichbar unter: <strong>localhost:7000/</strong>

<h2><strong>Routen:</strong></h2>

- <strong>/</strong>
→  dashboard.html

- <strong>/admin</strong>
→  admin_dashboard.html

- <strong>/admin/<string:mode></strong>
→  'login' or 'register'
→  erwartet username und password als json

- <strong>/events/getall</strong>
→  listet alle verfügbaren events + infos auf

- <strong>/events/getlikes</strong>
→  listet nur die likes auf (für DomContentLoaded zum aktuallisieren von Likes)

- <strong>/events/addlike/<int:id></strong>
→ erwartet eine ID
→ fügt ein Like hinzu (erst senden, dann getLikes aufrufen)

- <strong>/events/create/</strong>
→  erstellt ein Event
→  erwartet name, description, date, location, category als json

- <strong>/events/delete/<int:id></strong>
→  löscht ein Event


<h2><strong>ToDo´s:</strong></h2>

- Server 🆗
####################################################################################
- Admin Login html 🆗
- Admin Login js 🆗
- Admin Dashboard
####################################################################################
- Dashboard 🆗
- Dashboard css 🆗
- Dashboard js 🆗
####################################################################################

# Fertig - 15.05.2025 - xXGrowGuruXx
