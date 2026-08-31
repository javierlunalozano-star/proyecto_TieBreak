/// Tipo de ficha. Añadir un valor aquí basta para introducir un tipo nuevo.
enum TileKind {
  defensa,
  colocacion,
  ataque,
  libero;

  String get label => switch (this) {
    TileKind.defensa => 'Defensa',
    TileKind.colocacion => 'Colocación',
    TileKind.ataque => 'Ataque',
    TileKind.libero => 'Líbero',
  };

  String get initials => switch (this) {
    TileKind.defensa => 'DEF',
    TileKind.colocacion => 'COL',
    TileKind.ataque => 'ATA',
    TileKind.libero => 'LÍB',
  };
}
