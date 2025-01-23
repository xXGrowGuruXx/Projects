from io import BytesIO
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Table, TableStyle, Image, Spacer
import os
from PyPDF2 import PdfReader, PdfWriter

def create_invoice(template_path, filename, logo_path, company_info, customer_info, items, total_amount):
    temp_buffer = BytesIO()
    document = SimpleDocTemplate(
        temp_buffer,
        pagesize=letter,
        leftMargin=20,
        rightMargin=20,
        topMargin=20,
        bottomMargin=20
    )
    styles = getSampleStyleSheet()
    
    # Zusätzliche Styles definieren (optional)
    styles.add(ParagraphStyle(name='RightAlign', alignment=2))  # 2 steht für rechtsbündig

    elements = []

    # Logo hinzufügen
    logo = None
    if os.path.exists(logo_path):
        logo = Image(logo_path, width=130, height=130)
    else:
        print("Logo-Datei nicht gefunden.")

    # Kundeninformationen mit Kundennummer
    customer_data = [
        [Paragraph(f"<b>Kunde:</b> {customer_info['name']}", styles['Normal'])],
        [Paragraph(f"<b>Kundennummer:</b> {customer_info['kundennummer']}", styles['Normal'])],
        [Paragraph(f"<b>Adresse:</b> {customer_info['address']}", styles['Normal'])],
        [Paragraph(f"<b>Datum:</b> {customer_info['date']}", styles['Normal'])]
    ]

    customer_table = Table(customer_data, colWidths=250)
    customer_table.setStyle(TableStyle([
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('GRID', (0, 0), (-1, -1), 0, colors.transparent)
    ]))

    # Container für Logo
    logo_data = []
    if logo:
        logo_data.append([logo])
    logo_table = Table(logo_data, colWidths=80)
    logo_table.setStyle(TableStyle([
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
    ]))

    # Geschäftsinformationen
    company_data = [
        [Paragraph(company_info['name'], styles['Title'])],
        [Table(
            [
            [Paragraph(f"<b>Adresse:</b> {company_info['address']}", styles['Normal'])],
            [Paragraph(f"<b>Kontakt:</b> {company_info['kontakt']}", styles['Normal'])]
            ],
            colWidths=[200, 80],
            hAlign='RIGHT'
        )]
    ]

    company_table = Table(company_data, colWidths=200)
    company_table.setStyle(TableStyle([
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
    ]))

    # Haupttabelle für Header
    header_data = [[customer_table, logo_table, company_table]]
    header_table = Table(header_data, colWidths=[250, 100, 242])

    elements.append(Spacer(1, -40))
    elements.append(header_table)
    elements.append(Spacer(1, 80))

    # Titel der Rechnung mit Rechnungsnummer
    elements.append(Paragraph(f"Rechnung Nr. {customer_info['rechnungsnummer']}", styles['Title']))
    elements.append(Spacer(1, 40))

    # Warenauflistung
    table_data = [["Artikel", "Menge", "Einzelpreis", "Gesamtpreis"]]
    for i, item in enumerate(items):
        total_price = item['quantity'] * item['unit_price']
        row = [
            item['name'],
            item['quantity'],
            f"{item['unit_price']:.2f} €",
            f"{total_price:.2f} €"
        ]
        table_data.append(row)

    # Leere Zeile einfügen
    table_data.append(["", "", "", ""])

    # Gesamtbetrag-Zeile hinzufügen
    table_data.append(["", "", "Gesamtbetrag:", f"{total_amount:.2f} €"])

    table = Table(table_data, colWidths=[250, 50, 100, 100])

    # Styling für abwechselnde Zeilenfarbe und Header
    table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
        ('GRID', (0, 0), (-1, -1), 1, colors.black),
        ('BACKGROUND', (0, 1), (-1, -1), colors.whitesmoke),  # Standardhintergrund für Zeilen
    ]))

    # Abwechselnde Zeilenfarbe
    for row in range(1, len(table_data)-2):  # -2, um die Leer- und Gesamtbetragzeile zu ignorieren
        bg_color = colors.lightgrey if row % 2 == 0 else colors.whitesmoke
        table.setStyle(TableStyle([
            ('BACKGROUND', (0, row), (-1, row), bg_color)
        ]))

    # Warentabelle und Spacer hinzufügen
    elements.append(table)
    elements.append(Spacer(1, 10))

    # MwSt.-Hinweis mit einer Breite von 200, rechtsbündig ausgerichtet
    mwst_text = Table(
        [[Paragraph("<b>Hinweis: Nach §19 UStG keine MwSt.</b>", styles['Normal'])]],
        colWidths=[210]
    )
    mwst_text.hAlign = 'RIGHT'
    elements.append(mwst_text)
    elements.append(Spacer(1, 60))

    # Abschließende Texte mit einer Breite von 400, rechtsbündig ausgerichtet
    final_text1 = Table(
        [
            [Paragraph("<b>Vielen Dank für Ihren Einkauf.</b>", styles['Normal'])],
        ],
        colWidths=[180]
    )
    final_text1.hAlign = 'CENTER'
    elements.append(final_text1)
    elements.append(Spacer(1, 20))
    final_text2 = Table(
        [
            [Paragraph("<b>Wir würden uns freuen, wenn Sie unsere Produkte weiter empfehlen.</b>", styles['Normal'])]
        ],
        colWidths=[350]
    )
    final_text2.hAlign = 'CENTER'
    elements.append(final_text2)
    elements.append(Spacer(1, 60))

    # Zahlungsinformationen mit QR-Code rechts
    zahlungsinformation_text = Table(
        [
            [
                # Linke Spalte: Text
                [
                    Paragraph("<b>Bitte Überweisen Sie den angegebenen Betrag innerhalb von <b>14 Tagen</b> auf das unten stehende Konto.</b>", styles['Normal']),
                    Paragraph("<b>Andernfalls wird die Bestellung storniert.</b>", styles['Normal']),
                    Paragraph("&nbsp;", styles['Normal']),  # Leerzeile
                    Paragraph("<b>Über die Stornierung werden Sie benachrichtigt.</b>", styles['Normal']),
                    Paragraph("&nbsp;", styles['Normal']),  # Leerzeile
                    Paragraph("&nbsp;", styles['Normal']),  # Leerzeile
                    Paragraph("<b>Die Ware wird nach Buchungseingang versendet.</b>", styles['Normal'])
                ],
            ]
        ],
        colWidths=[400, 100]  # Breite der Spalten anpassen
    )

    # Stil für die Tabelle festlegen (optional)
    zahlungsinformation_text.setStyle(TableStyle([
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),  # Text oben ausrichten
        ('LEFTPADDING', (0, 0), (-1, -1), 30),
        ('RIGHTPADDING', (0, 0), (-1, -1), 10),
    ]))

    # Tabelle hinzufügen
    zahlungsinformation_text.hAlign = 'LEFT'
    elements.append(zahlungsinformation_text)
    elements.append(Spacer(1, 45))

    # Kontoinformationen als Footer nebeneinander
    kontoinformation_text = Table(
        [
            [Paragraph("<b>Institut: N26</b>", styles['Normal']),
            Paragraph("<b>IBAN: DE12 3456 7890 1234 5678 90</b>", styles['Normal']),
            Paragraph("<b>BIC: XXXXXXXXXXX</b>", styles['Normal'])]
        ],
        colWidths=[120, 220, 120]  # Breite der Spalten anpassen
    )
    kontoinformation_text.hAlign = 'CENTER'
    elements.append(kontoinformation_text)

    document.build(elements)

    temp_buffer.seek(0)

    # Vorlage öffnen und Inhalte einfügen
    template_reader = PdfReader(template_path)
    template_page = template_reader.pages[0]

    content_reader = PdfReader(temp_buffer)
    content_page = content_reader.pages[0]

    # Vorlage und Inhalt zusammenführen
    template_page.merge_page(content_page)

    # Neue PDF speichern
    pdf_writer = PdfWriter()
    pdf_writer.add_page(template_page)

    with open(filename, "wb") as output_pdf:
        pdf_writer.write(output_pdf)

if __name__ == "__main__":
    logo_path = "logo.png"
    template_path = "vorlage.pdf"
    company_info = {
        "name": "Stechauer Tropfhonig",
        "address": "Musterstr 25, 12345 Musterstadt",
        "kontakt": "0156/12345678"
    }

    customer_info = {
        "name": "Max Mustermann",
        "address": ", 12345 Musterstadt",
        "date": "16.12.2024",
        "kundennummer": "10084",
        "rechnungsnummer": "RE2024-0128"
    }

    items = [
        {"name": "Tropfhonig - 420g", "quantity": 1, "unit_price": 15}
    ]

    total_amount = sum(item['quantity'] * item['unit_price'] for item in items)

    # Ordner Rechnungen sicherstellen
    output_dir = "Rechnungen"
    os.makedirs(output_dir, exist_ok=True)
    # Dateipfad der PDF mit Rechnungsnummer
    pdf_filename = os.path.join(output_dir, f"{customer_info['rechnungsnummer']}.pdf")
    # PDF erstellen
    create_invoice(template_path, pdf_filename, logo_path, company_info, customer_info, items, total_amount)

    
    # ANSI Escape Sequence für grün
    GREEN = "\033[92m"
    RED = "\033[91m"
    RESET = "\033[0m"  # Zurücksetzen auf die Standardfarbe

    # Nachricht in grün ausgeben
    print(f"{GREEN}PDF für Rechnung: {RED}{customer_info['rechnungsnummer']}{GREEN} erstellt.{RESET}")
