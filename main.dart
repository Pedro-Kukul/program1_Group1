import 'dart:convert';
import 'dart:io';

// Regular expressions for various components of the language
final halt = RegExp(r"^HALT$", caseSensitive: false);
final r_on = RegExp(r"^ON$", caseSensitive: false);
final r_off = RegExp(r"^OFF$", caseSensitive: false);
final r_sqr = RegExp(r"^sqr$", caseSensitive: false);
final r_tri = RegExp(r"^tri$", caseSensitive: false);
final r_xyChain = RegExp(r"^([a-f][1-6]),([a-f][1-6])(,([a-f][1-6]))?$");
final r_delim = RegExp(r"^-$");

// Helper function for printing
Future<void> myPrint(String output) async {
  stdout.write(output);
}

// Helper function for taking user input
String? myInput(String prompt) {
  myPrint(prompt);
  return stdin.readLineSync(encoding: utf8);
}

// Main program loop
void main() {
  while (true) {
    myPrint('-' * stdout.terminalColumns);
    displayGrammar();
    String? userInput = myInput("Enter your : ");

    if (userInput != null && halt.hasMatch(userInput)) {
      break;
    } else if (userInput != null) {
      if (rightmostDerivation(userInput)) {
        myInput("Press enter to continue: ");
        showDerivation(userInput);
      }
    }
  }
}

// Function to display the grammar
void displayGrammar() {
  List<List<String>> grammar = [
    ['<proc>', '➝', '', 'ON <instructions> OFF'],
    ['<instructions>', '➝', '', '<line>'],
    ['', '', '|', '<line> - <instructions>'],
    ['<line>', '➝', '', 'sqr <xy>,<xy>'],
    ['', '', '|', 'tri <xy>,<xy>,<xy>'],
    ['<xy>', '➝', '', '<x><y>'],
    ['<x>', '➝', '', 'a | b | c | d | e | f'],
    ['<y>', '➝', '', '1 | 2 | 3 | 4 | 5 | 6 |']
  ];
  for (var line in grammar) {
    myPrint(
        '${line[0].padRight(15)} ${line[1].padRight(10)} ${line[2].padRight(1)} ${line[3]} \n');
  }
}

List<String> derviationSteps() {}

// Show derivation steps
void showDerivation(List<String> derivation) {
  myPrint("Derivation Steps for: $input\n");

  // First item for the counter should be blank, then <proc>
  String firstLine = derivation.isNotEmpty ? derivation[0] : '';

  // Print the initial step with padding
  print(
      '${' '.padRight(5)} ${'<proc>'.padRight(15)} ${'➝'.padRight(15)} $firstLine');

  // Display each derivation step
  for (int i = 1; i < derivation.length; i++) {
    String stepNumber = (i + 1).toString().padLeft(2, '0');
    String nextDerivation = derivation[i];
    print(
        '${stepNumber.padRight(5)} ${' '.padRight(15)} ${'➝'.padRight(15)} $nextDerivation');
  }
}

// Error reporting for incorrect lines
void reportError(List<String> checked, List<String> input, String expected) {
  String errorToken = input.isNotEmpty ? input.removeLast() : 'Missing';
  String whiteSpace = ''.padLeft(input.join(' ').length);
  printSyntaxError(input, errorToken, whiteSpace, expected);
}

// Error for invalid XY chain
void processXYChainError(List<String> checked, List<String> input) {
  String errorToken = input.isNotEmpty ? input.removeLast() : 'Missing';
  String whiteSpace = ''.padLeft(input.join(' ').length);
  if (RegExp(r"[a-f]").hasMatch(errorToken[0])) {
    myPrint("\nError: ${errorToken} contains an invalid Y coordinate.\n");
  } else {
    myPrint("\nError: ${errorToken} contains an invalid X coordinate.\n");
  }
  printSyntaxError(input, errorToken, whiteSpace, "valid XY format");
}

// Error for invalid shape
void reportShapeError(List<String> checked, List<String> input) {
  String errorToken = input.isNotEmpty ? input.removeLast() : 'Missing';
  myPrint(
      "\nError: Shape '${errorToken}' is not valid (expected 'sqr' or 'tri').\n");
}

// Print syntax error
void printSyntaxError(
    List<String> input, String errorToken, String whiteSpace, String expected) {
  myPrint("\nInput: ${input.join(' ')} $errorToken\n");
  myPrint("$whiteSpace${'^' * errorToken.length}\n");
  myPrint(
      "Syntax Error: Expected \"$expected\", but found \"$errorToken\" instead.\n");
}
