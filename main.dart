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
    String? userInput = myInput("Enter your sentence: ");

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

List<String> derivationSteps = [];

// Rightmost derivation functionA
bool rightmostDerivation(String input) {
  derivationSteps.clear();

  try {
    // Trim and split the input
    input = input.trim();
    List<String> tokenList = input.split(RegExp(r"\s*[,]\s*|\s+"));

    if (!r_on.hasMatch(tokenList.first)) {
      throw ("'ON' is missing.");
    }
    if (!r_off.hasMatch(tokenList.last)) {
      throw ("'OFF' is missing.");
    }

    // Remove ON and OFF from the token list
    tokenList.removeAt(0); // Remove 'ON'
    tokenList.removeLast(); // Remove 'OFF'

    // Start derivation
    derivationSteps.add("ON <instructions> OFF");
    if (!processInstructions(tokenList)) {
      return false;
    }
  } catch (e) {
    print('Error: $e');
    return false;
  }

  return true;
}

// Process instructions recursively
bool processInstructions(List<String> tokenList) {
  if (tokenList.isEmpty) return false;

  // Check if the instruction contains multiple lines
  if (tokenList.contains('-')) {
    int index = tokenList.indexOf('-');
    List<String> firstPart = tokenList.sublist(0, index);
    List<String> secondPart = tokenList.sublist(index + 1);

    // Derive the rightmost instruction first
    derivationSteps.add("<line> - <line>");
    if (!processInstructions(secondPart)) return false;
    if (!processLine(firstPart)) return false;
  } else {
    // Single instruction case
    derivationSteps.add("<line>");
    if (!processLine(tokenList)) return false;
  }

  return true;
}

// Process a single line
bool processLine(List<String> tokenList) {
  if (tokenList.isEmpty) return false;

  // Check for 'sqr' or 'tri'
  if (r_sqr.hasMatch(tokenList.first)) {
    if (tokenList.length == 3 &&
        r_xyChain.hasMatch(tokenList.sublist(1).join(','))) {
      derivationSteps.add("sqr <xy>,<xy>");
      String xyChain = tokenList.sublist(1).join(',');
      processXYChain(xyChain);
    } else {
      reportError([], tokenList, "valid 'sqr' line");
      return false;
    }
  } else if (r_tri.hasMatch(tokenList.first)) {
    if (tokenList.length == 4 &&
        r_xyChain.hasMatch(tokenList.sublist(1).join(','))) {
      derivationSteps.add("tri <xy>,<xy>,<xy>");
      String xyChain = tokenList.sublist(1).join(',');
      processXYChain(xyChain);
    } else {
      reportError([], tokenList, "valid 'tri' line");
      return false;
    }
  } else {
    reportShapeError([], tokenList);
    return false;
  }

  return true;
}

// Process XY chain
void processXYChain(String xyChain) {
  var xyList = xyChain.split(',');
  for (var xy in xyList.reversed) {
    derivationSteps.add("$xy");
  }
}

// Show derivation steps
void showDerivation(String input) {
  myPrint("Derivation Steps for: $input\n");

  // First item for the counter should be blank, then <proc>
  String firstLine = derivationSteps.isNotEmpty ? derivationSteps[0] : '';

  // Print the initial step with padding
  print(
      '${' '.padRight(5)} ${'<proc>'.padRight(15)} ${'➝'.padRight(15)} $firstLine');

  // Display each derivation step
  for (int i = 1; i < derivationSteps.length; i++) {
    String stepNumber = (i + 1).toString().padLeft(2, '0');
    String derivation = derivationSteps[i];
    print(
        '${stepNumber.padRight(5)} ${' '.padRight(15)} ${'➝'.padRight(15)} $derivation');
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
