/// Represents the classified intent of a user query.
enum QueryIntent {
  /// A question seeking information (e.g., "What is my blood pressure?")
  question("Question"),

  /// A command requesting an action (e.g., "Show me my records")
  command("Command"),

  /// A statement providing information (e.g., "I took my medication")
  statement("Statement"),

  /// A greeting or simple expression (e.g., "Hello", "Hi")
  greeting("Greeting");

  const QueryIntent(this.displayName);
  
  /// User-friendly display name for the intent.
  final String displayName;

  @override
  String toString() {
    return displayName;
  }
}