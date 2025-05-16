from pathlib import Path

def get_database_uri(event: str) -> str:
    db_dir = Path(__file__).parent / "../databases"
    db_dir.mkdir(exist_ok=True)
    return f"sqlite:///{db_dir / f'{event}.db'}"