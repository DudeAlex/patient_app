import 'package:patient_app/core/ai/chat/models/space_context.dart';

/// Abstraction for building SpaceContext (e.g., with recent records/persona).
abstract class SpaceContextBuilder {
  Future<SpaceContext> build(String spaceId);
}
