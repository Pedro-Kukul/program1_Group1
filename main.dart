import 'dart:convert';
import 'dart:io';

final r_sqr = RegExp(r'sqr\s+[a-z]+\d{1,2}(?:,[a-z]+\d{1,2})');
final r_tri = RegExp(r"tri\s+[a-z]+\d{1,2}(?:,[a-z]+\d{1,2}){2}");
final r_delim = RegExp(r"-");
final r_instructions = RegExp(r"ON|OFF|([a-zA-Z]{3})\s+([a-zA-Z]\d+,?)+|-");
final r_halt = RegExp(r'^HALT$');
final r_on = RegExp(r"^ON");
final r_off = RegExp(r"OFF$");
final r_line =
    RegExp(r'^(?:-)?[a-zA-Z]{3}\s+[a-z]+\d{1,2}(?:,[a-z]+\d{1,2}){1,2}$');
final r_shape = RegExp(
    r'\s*(?:tri\s+[a-z]+\d{1,2}(?:,[a-z]+\d{1,2}){2}|sqr\s+[a-z]+\d{1,2}(?:,[a-z]+\d{1,2}))');
final r_single_coordinate = RegExp(r'[a-z]\d+');
final r_x = RegExp(r'[a-f]');
final r_y = RegExp(r'[1-6]');

/********************************************************************************************************************************************* */
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

// Lists Used might refactor
List<String> derivationSteps = [];
List<String> checkedList = [];
List<String> lines = [];

/********************************************************************************************************************************************* */

// Function to add a derivation step
// Paramaters are what to replace and what tozz
void updateDerivationSteps(String target, String replacement) {
  // If this is empty then return since theres nothing to do
  if (derivationSteps.isEmpty) return;
  // Last derivation step
  String lastStep = derivationSteps.last;
  // for searching the rightmost of the step
  int lastIndex = lastStep.lastIndexOf(target);

  // Begins searching from right to left and replaces the rightmost target first.
  if (lastIndex != -1) {
    derivationSteps.add(lastStep.replaceRange(
        lastIndex, lastIndex + target.length, replacement));
  }
}

// Helper Function to print a message
// Could maybe remove this
Future<void> myPrint(String output) async {
  stdout.write(output);
}

// Helper function to recieve input
// Could maybe remove this
String? myInput(String prompt) {
  myPrint("\n" + prompt);
  return stdin.readLineSync(encoding: utf8);
}

// Helper function to print a line of characters with an optional message
void printCharacters(String message, String symbol) {
  int totalColumns = stdout.terminalColumns;
  int symbolCount = totalColumns - message.length;

  if (symbolCount > 0) {
    print(message + symbol.padRight(symbolCount, symbol));
  }
}

// Check for HALT to terminate program additionally checks if the user misscapitalized the termination code
bool checkHalt(String input) {
  if (r_halt.hasMatch(input)) {
    return true;
  } else if (r_halt.hasMatch(input.toUpperCase())) {
    throw "Syntax Error: Use 'HALT' to terminate the program.";
  }
  return false;
}

// Displays Grammar neatly
void displayGrammar() {
  printCharacters("\n", "-");
  print("Grammar:");
  for (var line in grammar) {
    print(
        '${line[0].padRight(15)} ${line[1].padRight(10)} ${line[2].padRight(1)} ${line[3]}');
  }
  printCharacters("", "-");
}

String ThrowSyntaxError(String expected, String error) {
  return "Syntax Error: Expected $expected; but received $error at ${checkedList.last} instead";
}

/********************************************************************************************************************************************* */
// Function to process the individual coordinates
bool processXY(List<String> tokenList) {
  if (tokenList.isEmpty) return true;
  String component = tokenList.removeLast();
  if (RegExp(r"[0-9]").hasMatch(component)) {
    if (r_y.hasMatch(component)) {
      updateDerivationSteps("<y>", component);
    } else {
      throw ThrowSyntaxError("1-6", component);
    }
  } else if (RegExp(r"[a-z]").hasMatch(component)) {
    if (r_x.hasMatch(component)) {
      updateDerivationSteps("<x>", component);
    } else {
      throw ThrowSyntaxError("a-z", component);
    }
  } else {
    throw "Unexpected component format: $component";
  }
  return processXY(tokenList);
}

// recieves coordinaes for a shape, furthur derives them
bool processCoordinates(List<String> tokenList) {
  if (tokenList.isEmpty) return true;
  String coordinate = tokenList.removeLast();
  checkedList.add(coordinate);
  if (r_single_coordinate.hasMatch(coordinate)) {
    updateDerivationSteps("<xy>", "<x><y>");
    List<String> components = coordinate.split("");
    processXY(components);
  } else {
    ThrowSyntaxError("<xy>", coordinate);
  }
  return processCoordinates(tokenList);
}

// recieve shapes with their cooredinates, send its coordinates to further derive
// Splits the line into shapes and coordinates shape + coordinates
// sqr|tri and their coordinates <xy>,<xy> for sqr  and <xy>,<xy>,<xy> for tri.
// Depending the shape the the coordinatesList should only be either 2 or 3 for sqr or tri
// send the coordinatesList to process, all error checking for it should be done here
bool processLines(List<String> tokenList) {
  if (tokenList.isEmpty) return true;

  // Remove and process the current line
  String line = tokenList.removeAt(0).trim();

  // Parse the line into components (shape and coordinates) Split by whitespace or commas
  List<String> lineComponents = line.split(RegExp(r"[\s,]+"));
  lineComponents.forEach(print);
  // First part is the shape (e.g., "tri" or "sqr") IT WILL ALWAYS BE SHAPE BECAUSE OF PREVIOUS CORRECTIONS
  String shape = lineComponents[0];
  // Variable to hold the expected number of coordinates
  int shapeCoordinateLength;

  // Determine the expected number of coordinates based on the shape
  if (RegExp(r"tri").hasMatch(shape.trim())) {
    shapeCoordinateLength = 3; // Triangle needs 3 coordinates
    updateDerivationSteps("<line>", "tri <xy>,<xy>,<xy>");
  } else if (RegExp(r"sqr").hasMatch(shape.trim())) {
    shapeCoordinateLength = 2; // Square needs 2 coordinates
    updateDerivationSteps("<line>", "sqr <xy>,<xy>");
  } else {
    throw ArgumentError(
        "Error Processing: '$line' is not a valid shape (expected 'tri' or 'sqr')");
  }

  // Validate that the number of coordinates matches the expected shape
  List<String> coordinatesList =
      lineComponents.sublist(1); // All components after shape are coordinates
  if (coordinatesList.length != shapeCoordinateLength) {
    throw ArgumentError(
        "Error: Expected $shapeCoordinateLength coordinates for '$shape', but got ${coordinatesList.length} in $line");
  }

  // Further process the coordinates list if valid
  processCoordinates(coordinatesList);

  // Recursively process the next line
  return processLines(tokenList);
}

// recieves instrcutions, sends them to derieve as lines furhter
bool processInstructions(List<String> tokenList) {
  if (tokenList.isEmpty) return false;
  try {
    lines.add(tokenList.removeLast());
    if (tokenList.isNotEmpty) {
      updateDerivationSteps("<instructions>", "<line> - <instructions>");
      return processInstructions(tokenList);
    }
    updateDerivationSteps("<instructions>", "<line>");
    return processLines(lines);
  } catch (e) {
    throw ThrowSyntaxError("a proper instructor", "$e");
  }
}

// attempts derivaiton
bool attemptDerivation(String input) {
  derivationSteps.clear();
  checkedList.clear();
  lines.clear();
  List<String> unrecognizedTokens = [];

  try {
    if (input.isEmpty) throw ArgumentError("Input cannot be empty.");

    // Tokenize the string on nonterminals
    Iterable<RegExpMatch> matches = r_instructions.allMatches(input);
    List<String> matchedTokens = matches
        .map((match) => match.group(0)!.trim())
        .where((element) => element.isNotEmpty)
        .toList();

    String filteredInput = input;
    for (String token in matchedTokens) {
      filteredInput = filteredInput.replaceFirst(token, '');
    }

    unrecognizedTokens = filteredInput
        .split(RegExp(r'\s+')) // Split by whitespace
        .where((token) => token.isNotEmpty) // Remove empty tokens
        .toList();

    if (unrecognizedTokens.isNotEmpty) {
      throw FormatException(
          "Unrecognized instruction(s): ${unrecognizedTokens.join(', ')}");
    }
    if (matchedTokens.isEmpty) throw ArgumentError("Enter a proper Sentence!");
    if (!r_on.hasMatch(matchedTokens.first)) {
      throw ArgumentError("Sentence must start with 'ON'.");
    }
    if (!r_off.hasMatch(matchedTokens.last)) {
      throw ArgumentError("Sentence must end with 'OFF'.");
    }
    checkedList.add(matchedTokens.removeAt(0));
    checkedList.add(matchedTokens.removeLast());
    // Remove the delimeters
    matchedTokens.removeWhere((element) => r_delim.hasMatch(element));
    if (matchedTokens.isEmpty) {
      throw FormatException(
          "Sentence must contain instructions between 'ON' and 'OFF'.");
    }
    // Begin the tracking of derivation Steps
    derivationSteps.add("${checkedList[0]} <instructions> ${checkedList.last}");

    // send only the instructions (shape + coordinates) to process
    return processInstructions(matchedTokens);
  } catch (e) {
    throw e;
  }
}

void showDerivation() {
  myPrint(
      '${' '.padRight(5)} ${'<proc>'.padRight(15)} ${'➝'.padRight(15)} ${derivationSteps[0]}\n');
  for (int i = 1; i < derivationSteps.length; i++) {
    String stepNumber = (i + 1).toString().padLeft(2, '0');
    myPrint(
        '${stepNumber.padRight(5)} ${' '.padRight(15)} ${'➝'.padRight(15)} ${derivationSteps[i]}\n');
  }
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

// Function to draw the parse tree for the recognized string
void drawParseTree(String input) {
  print("Parse Tree:");

  // Split the input string to separate ON, OFF, and the instructions
  if (input.startsWith('ON') && input.endsWith('OFF')) {
    print("<proc>");
    print(" ├── ON");

    // Remove "ON" and "OFF" to isolate the body
    String body = input.substring(3, input.length - 3).trim();
    drawInstructions(body);

    print(" └── OFF");
  } else {
    print("Error: Invalid structure.");
  }
}

// Helper function to draw instructions
void drawInstructions(String instructions) {
  print(" ├── <body>");
  print(" │    ├── <instructions>");

  // Split the instructions on " - " to handle multiple lines
  List<String> lines = instructions.split(' - ');

  for (int i = 0; i < lines.length; i++) {
    drawLine(lines[i]);

    // For the last line, don't print a '-' node
    if (i < lines.length - 1) {
      print(" │    ├── -");
    }
  }
}

// Helper function to draw a single line (sqr or tri)
void drawLine(String line) {
  if (line.startsWith('sqr')) {
    print(" │    ├── <line> (sqr)");
    // Extract the coordinates
    String coords = line.substring(4);
    List<String> xy = coords.split(',');

    drawXY(xy[0].trim(), 1); // First xy
    drawXY(xy[1].trim(), 2); // Second xy
  } else if (line.startsWith('tri')) {
    print(" │    ├── <line> (tri)");
    // Extract the coordinates
    String coords = line.substring(4);
    List<String> xy = coords.split(',');

    drawXY(xy[0].trim(), 1); // First xy
    drawXY(xy[1].trim(), 2); // Second xy
    drawXY(xy[2].trim(), 3); // Third xy
  } else {
    print("Error: Invalid line structure.");
  }
}

// Helper function to draw the <xy> for each coordinate
void drawXY(String xy, int index) {
  String x = xy[0];
  String y = xy[1];

  print(" │    │    ├── <xy> $index");
  print(" │    │    │    ├── <x> $x");
  print(" │    │    │    └── <y> $y");
}

// Main program loop
void main() {
  while (true) {
    try {
      displayGrammar();
      String userInput = myInput("Enter your sentence: ") ?? "";

      if (checkHalt(userInput)) {
        printCharacters("Terminating Program", ".");
        break;
      } else {
        // Perform derivation and parse tree steps if "HALT" is not entered
        attemptDerivation(userInput);
        myInput("Press any key to continue?"); // Wait for user to proceed
        showDerivation();
        myInput("Press any key to continue?"); // Show derivation or parse tree
        drawParseTree(userInput);
      }
    } catch (e) {
      print(e);
    }
  }
}
