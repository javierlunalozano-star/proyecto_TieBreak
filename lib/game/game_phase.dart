enum GamePhase {
  /// El jugador reordena las fichas de la cuadrícula (sin el líbero).
  setup,

  /// Cada jugador puede hacer un cambio de líbero y confirmar que está listo.
  substitution,

  /// Solo se deslizan fichas adyacentes al hueco.
  play,
}
