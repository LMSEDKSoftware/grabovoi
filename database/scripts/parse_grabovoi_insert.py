#!/usr/bin/env python3
"""
Parsea grabovoi_codigos_insert.sql (estructura ChatGPT) y genera
INSERT para codigos_grabovoi de Supabase.
"""
import re
import sys

SRC = "/Users/ifernandez/Downloads/grabovoi_codigos_insert.sql"
OUT = "/Users/ifernandez/development/grabovoi_build/database/supabase_codigos_grabovoi_insert.sql"

# Mapeo: categoría detallada → grupo simple (como en Supabase: Salud, Abundancia, Amor, etc.)
CATEGORIA_SIMPLE = {
    "Salud crítica": "Salud",
    "Tumores": "Salud",
    "Digestivo": "Salud",
    "Endocrino": "Salud",
    "Cardiovascular": "Salud",
    "Respiratorio": "Salud",
    "Nervioso": "Salud",
    "Renal/urinario": "Salud",
    "Reproductor": "Salud",
    "Infecciosas": "Salud",
    "Piel": "Salud",
    "Músculo-esquelético": "Salud",
    "Ojos/Oídos": "Salud",
    "Dolor/Inflamación": "Salud",
    "Inmunidad": "Salud",
    "Emocional/Mental": "Crecimiento personal",
    "Energía/Vitalidad": "Energía y vitalidad",
    "Otros": "Otros",
}

def escape_sql(s: str) -> str:
    """Escapa comillas simples para SQL."""
    return s.replace("'", "''")

def extract_row(line: str):
    """Extrae (codigo, nombre, descripcion, categoria, color) de una línea VALUES."""
    # Patrón: 5 strings entre comillas simples (el contenido puede tener '' escapado)
    pattern = r"'((?:[^']|'')*?)'"
    matches = re.findall(pattern, line)
    if len(matches) >= 5:
        codigo, nombre, descripcion, categoria, color = matches[0], matches[1], matches[2], matches[3], matches[4]
        return (escape_sql(codigo), escape_sql(nombre), escape_sql(descripcion), escape_sql(categoria), escape_sql(color))
    return None

def main():
    rows = []
    with open(SRC, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("--"):
                continue
            # Ignorar línea de cabecera INSERT INTO ... VALUES
            if line.startswith("INSERT INTO"):
                continue
            # Cada línea de datos: (n, gen_random_uuid(), 'codigo', 'nombre', ...
            if line.startswith("(") and "gen_random_uuid()" in line:
                line_clean = line.rstrip(");").rstrip(",").strip()
                row = extract_row(line_clean)
                if row:
                    codigo, nombre, descripcion, categoria, color = row
                    categoria_simple = CATEGORIA_SIMPLE.get(categoria, "Otros")
                    rows.append((codigo, nombre, descripcion, categoria_simple, color))
    # Generar SQL (schema real: public.codigos_grabovoi con UNIQUE(codigo), columna color)
    # ON CONFLICT (codigo) DO UPDATE para que no falle con códigos duplicados (última fila gana)
    batch_size = 80
    # DO NOTHING: si el codigo ya existe (en DB o en el mismo INSERT), se omite.
    # Evita el error "cannot affect row a second time" por duplicados en el mismo batch.
    on_conflict = """
ON CONFLICT (codigo) DO NOTHING;
"""
    with open(OUT, "w", encoding="utf-8") as out:
        out.write("-- INSERT de códigos Grabovoi para Supabase (public.codigos_grabovoi)\n")
        out.write("-- Categorías en grupos simples: Salud, Crecimiento personal, Energía y vitalidad, Otros\n")
        out.write("-- Si el codigo ya existe en la DB (o en el mismo INSERT), se omite (DO NOTHING).\n\n")
        for i in range(0, len(rows), batch_size):
            chunk = rows[i : i + batch_size]
            values = ", ".join(
                f"('{codigo}', '{nombre}', '{descripcion}', '{categoria}', '{color}')"
                for (codigo, nombre, descripcion, categoria, color) in chunk
            )
            out.write("INSERT INTO public.codigos_grabovoi (codigo, nombre, descripcion, categoria, color)\n")
            out.write("VALUES\n")
            out.write(values)
            out.write("\n")
            out.write(on_conflict)
            out.write("\n")
    print(f"Generadas {len(rows)} filas en {OUT}")

if __name__ == "__main__":
    main()
