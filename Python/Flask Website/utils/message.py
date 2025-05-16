from colorama import init, Fore, Style
init(autoreset=True)


def _print_block(title: str, text: str, color: str):
    border = f"{color}{'#' * 60}"
    headline = f"{Style.BRIGHT}{color}{title.upper()}"

    print()
    print(border)
    print(headline.center(60))
    print(border)
    print(Fore.WHITE + text)
    print(border)
    print()


def request_message(text: str):
    _print_block("Server Request", text, Fore.CYAN)


def info_message(text: str):
    _print_block("Info", text, Fore.BLUE)


def warn_message(text: str):
    _print_block("Warnung", text, Fore.YELLOW)


def error_message(text: str):
    _print_block("Fehler", text, Fore.RED)


def success_message(text: str):
    _print_block("Erfolg", text, Fore.GREEN)