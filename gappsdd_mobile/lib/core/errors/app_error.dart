/// Base class for all domain errors in the app.
///
/// Each error carries a user-facing [message] (localized) and an optional
/// [cause] for logging/debugging.
sealed class AppError implements Exception {
  const AppError(this.message, {this.cause});

  /// Human-readable message suitable for display in a SnackBar or dialog.
  final String message;

  /// The underlying exception that triggered this error, if any.
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

// ─── Visit errors ────────────────────────────────────────────────────────────

/// Thrown when attempting to start a visit while one is already active.
class ActiveVisitExistsError extends AppError {
  const ActiveVisitExistsError()
      : super('Ya tienes una visita en progreso');
}

/// Thrown when a garden ID is not in the gardener's assigned list.
class GardenNotAssignedError extends AppError {
  const GardenNotAssignedError()
      : super('Jardín no Asignado');
}

/// Thrown when no assigned gardens are available.
class NoAssignedGardensError extends AppError {
  const NoAssignedGardensError()
      : super('No tienes jardines asignados');
}

/// Thrown when a visit cannot be found or loaded.
class VisitNotFoundError extends AppError {
  const VisitNotFoundError()
      : super('No se pudo abrir la visita');
}

/// Thrown when trying to edit timestamps on an active (not closed) visit.
class VisitNotClosedError extends AppError {
  const VisitNotClosedError()
      : super('Solo se pueden editar timestamps en visitas cerradas');
}

// ─── Chat errors ─────────────────────────────────────────────────────────────

/// Thrown when a conversation cannot be found or created.
class ConversationNotFoundError extends AppError {
  const ConversationNotFoundError()
      : super('No se pudo abrir la conversación');
}

/// Thrown when a message fails to send.
class MessageSendError extends AppError {
  const MessageSendError({Object? cause})
      : super('Error enviando mensaje', cause: cause);
}

// ─── Generic errors ──────────────────────────────────────────────────────────

/// Wraps an unexpected exception so that callers only need to catch [AppError].
class UnexpectedError extends AppError {
  const UnexpectedError(Object cause)
      : super('Ha ocurrido un error inesperado', cause: cause);
}
