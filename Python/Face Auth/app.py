import tkinter as tk
from tkinter import ttk
import register
import login

def open_register():
    register.register_user()

def open_login():
    login.login_user()

app = tk.Tk()
app.title("FaceAuth")
app.geometry("300x200")
app.configure(bg="#1e1e1e")

# Style für Dark Mode konfigurieren
style = ttk.Style(app)
style.theme_use('clam')  # Clam als Basis, weil gut anpassbar

# Farben definieren
bg_color = "#1e1e1e"
fg_color = "#eeeeee"
btn_bg = "#333333"
btn_fg = "#ffffff"
btn_hover = "#555555"
font = ("Helvetica", 12)

# Style für Labels
style.configure('TLabel', background=bg_color, foreground=fg_color, font=("Helvetica", 16, "bold"))

# Style für Buttons
style.configure('TButton',
                background=btn_bg,
                foreground=btn_fg,
                font=font,
                borderwidth=0,
                focusthickness=3,
                focuscolor='none')
style.map('TButton',
          background=[('active', btn_hover), ('!disabled', btn_bg)],
          foreground=[('active', btn_fg), ('!disabled', btn_fg)])

# Widgets
label = ttk.Label(app, text="FaceAuth")
label.pack(pady=20)

btn_register = ttk.Button(app, text="Registrieren", command=open_register)
btn_register.pack(pady=10)

btn_login = ttk.Button(app, text="Login", command=open_login)
btn_login.pack(pady=10)

app.mainloop()