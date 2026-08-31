enum GamePhase {
  /// El jugador reordena las fichas de la cuadrícula (sin el líbero).
  setup,

  /// Cada jugador puede cambiar el líbero con el banquillo.
  substitution,

  /// Solo se deslizan fichas adyacentes al hueco.
  play,
}
