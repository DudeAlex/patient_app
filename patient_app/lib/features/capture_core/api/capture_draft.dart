/// Draft data that capture modes can provide to pre-fill the review screen.
class CaptureDraft {
  const CaptureDraft({
    this.suggestedTitle,
    this.suggestedDetails,
    this.suggestedTags = const <String>{},
  });

  final String? suggestedTitle;
  final String? suggestedDetails;
  final Set<String> suggestedTags;

  CaptureDraft merge(CaptureDraft other) {
    return CaptureDraft(
      suggestedTitle: other.suggestedTitle ?? suggestedTitle,
      suggestedDetails: other.suggestedDetails ?? suggestedDetails,
      suggestedTags: {...suggestedTags, ...other.suggestedTags},
    );
  }
}
