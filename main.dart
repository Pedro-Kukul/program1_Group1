//Necessary Imports
import 'dart:convert'; // Encoding
import 'dart:io'; // I/O

//Regex
final r_halt = RegExp(r'^HALT$'); // Termination
final r_single_coordinate = RegExp(r'[a-z]\d+'); // XY
final r_x = RegExp(r'[a-f]'); // X
final r_y = RegExp(r'[1-6]'); // Y
final r_Line = RegExp(
    r'([a-z]{3}) ([a-z]\d)(?:,([a-z]\d))*'); // Line (Shape + coordinates)
final r_Terminals = RegExp(
    r'([a-z]{3}) ([a-z]\d)(?:,([a-z]\d))*|ON|OFF|-'); // Lines, -, ON, OFF

//Lists
final List<List<String>> grammar = [
  ['<proc>', '➝', '', 'ON <instructions> OFF'],
  ['<instructions>', '➝', '', '<line>'],
  ['', '', '|', '<line> - <instructions>'],
  ['<line>', '➝', '', 'sqr <xy>,<xy>'],
  ['', '', '|', 'tri <xy>,<xy>,<xy>'],
  ['<xy>', '➝', '', '<x><y>'],
  ['<x>', '➝', '', 'a | b | c | d | e | f'],
  ['<y>', '➝', '', '1 | 2 | 3 | 4 | 5 | 6 |']
]; // Grammar List
List<String> derivationSteps = []; // Tracking Derivation
List<String> linesDerived = []; // For Line derivation after instructions

//Helper Functions
// Replaces the rightmost target in the derivationSteps List and adds a new list item.
void updateDerivationSteps(String target, String replacement) {
  if (derivationSteps.isEmpty) return; // Return if empty
  String lastStep = derivationSteps.last; // Last derivation step
  // Rightmost target
  int lastIndex = lastStep.lastIndexOf(target);
  if (lastIndex != -1) {
    derivationSteps.add(lastStep.replaceRange(lastIndex,
        lastIndex + target.length, replacement)); // start, end , replace
  }
}

// Helper function to receive input
String? myInput(String prompt) {
  stdout.write(prompt);
  return stdin.readLineSync(encoding: utf8);
}

// Prints a line with symbols that covers the entire terminal line, optional message at the beginning
void printCharacters(String message, String symbol) {
  int totalColumns = stdout.terminalColumns;
  int symbolCount = totalColumns - message.length;
  if (symbolCount > 0) {
    print(message + symbol.padRight(symbolCount, symbol));
  }
}

// Checks for termination of the program
bool checkHalt(String input) {
  if (r_halt.hasMatch(input)) {
    return true;
  } else if (r_halt.hasMatch(input.toUpperCase()))
    throw "Syntax Error: Use 'HALT' to terminate the program.";
  else
    return false;
}

// Displays Grammar list in a formatted manner using string interpolation
void displayGrammar() {
  printCharacters("\n", "-");
  print("Grammar:");
  for (var line in grammar) {
    print(
        '${line[0].padRight(15)} ${line[1].padRight(10)} ${line[2].padRight(1)} ${line[3]}');
  }
  printCharacters("", "-");
}

//Derivation Subprogram
// Derives a coordinate
bool deriveXY(List<String> tokenList) {
  if (tokenList.isEmpty) return true; // return if no more tokens to derive
  // assigns and removes lastitem in the tokenList (starts from the last item and goes up)
  String component = tokenList.removeLast();
  // component is a number
  if (RegExp(r"[0-9]").hasMatch(component)) {
    // matches Y coordinate, updates the derivation steps, otherwise states where it could not derive
    if (r_y.hasMatch(component)) {
      updateDerivationSteps("<y>", component);
    } else {
      throw ArgumentError(["Expected 1-6 received:  $component"], "Syntax");
    }
    // component is a letter
  } else if (RegExp(r"[a-z]").hasMatch(component)) {
    // matches X coordinate, updates the derivation steps, otherwise states where it could not derive
    if (r_x.hasMatch(component)) {
      updateDerivationSteps("<x>", component);
    } else {
      throw ArgumentError(["Expected a-f received:  $component"], "Syntax");
    }
  } else {
    // unexpected errors
    throw "Unexpected component format: $component";
  }
  return deriveXY(tokenList);
}

// Receives coordinates, and for each pair, updates the derivation Steps
bool deriveCoordinates(List<String> tokenList) {
  if (tokenList.isEmpty) return true; // when empty done
  // assigns and removes the last item in the given token list (right to left)
  String coordinate = tokenList.removeLast();
  // checks for correct syntax, updates the coordinate in the derivationSteps List
  if (r_single_coordinate.hasMatch(coordinate)) {
    updateDerivationSteps("<xy>", "<x><y>");
    // Splits the coordinate into an x any y value
    List<String> components = coordinate.split("");
    // derives both coordinates
    deriveXY(components);
  } else {
    // throws error if found unexpected result
    throw ArgumentError(["Expected <x><y> received:  $coordinate"], "Syntax");
  }
  // recursive function to derive all items in the tokenlist
  return deriveCoordinates(tokenList);
}

// Derives a Line
bool deriveLines(List<String> tokenList) {
  if (tokenList.isEmpty) return true; // no more tokens to derive
  // assigns and removes the last lien in the tokenlist
  String line = tokenList.removeAt(0).trim();
  // Parse the line into components (shape and coordinates) Split by whitespace or commas (so the result would be individual coordinates and the shape)
  List<String> lineComponents = line.split(RegExp(r"[\s,]+"));
  // First part is the shape (e.g., "tri" or "sqr") IT WILL ALWAYS BE SHAPE BECAUSE OF PREVIOUS CORRECTIONS
  String shape =
      lineComponents[0]; // Variable to hold the expected number of coordinates
  int shapeCoordinateLength; // Determine the expected number of coordinates based on the shape
  if (RegExp(r"tri").hasMatch(shape.trim())) {
    shapeCoordinateLength = 3; // Triangle needs 3 coordinates
    updateDerivationSteps("<line>", "tri <xy>,<xy>,<xy>");
  } else if (RegExp(r"sqr").hasMatch(shape.trim())) {
    shapeCoordinateLength = 2; // Square needs 2 coordinates
    updateDerivationSteps("<line>", "sqr <xy>,<xy>");
  } else // Unexpected Shape
    throw ArgumentError(
        ["Error: '$line' is not a valid shape (expected 'tri' or 'sqr')"],
        "Syntax");
  // Validate that the number of coordinates matches the expected shape
  List<String> coordinatesList = lineComponents.sublist(1);
  // All components after shape are coordinates
  if (coordinatesList.length != shapeCoordinateLength)
    throw ArgumentError([
      // Throw error if got incorrect number of coordinates
      "Error: Expected $shapeCoordinateLength valid <xy> for '$shape', but got ${coordinatesList.length} valid <xy> in $line"
    ], "syntax");
  deriveCoordinates(coordinatesList); // Derive the coordinates list if notempty
  return deriveLines(tokenList); // Recursively derive the next line
}

// Receives instructions, sends them to derive as lines further
bool deriveInstructions(List<String> tokenList) {
  // when instructions have been derived to lines in derivationSteps then stops
  if (tokenList.isEmpty) return false;
  linesDerived.add(tokenList.removeLast());
  if (tokenList.isNotEmpty) {
    // If haven't reached last token in tokenlist
    updateDerivationSteps("<instructions>", "<line> - <instructions>");
    return deriveInstructions(tokenList);
  }
  // no more instructions to derive
  updateDerivationSteps("<instructions>", "<line>");
  return deriveLines(linesDerived);
}

bool attemptDerivation(String input) {
  // Clears Global ARrays
  derivationSteps.clear();
  linesDerived.clear();
  try {
    if (input.isEmpty) {
      throw ArgumentError("Input cannot be empty.");
    }
    // Tokenize the string on terminals (lines, -, ON, OFF)
    Iterable<RegExpMatch> matches = r_Terminals.allMatches(input);
    List<String> matchedTokens = matches
        .map((match) => match.group(0)!.trim())
        .where((element) => element.isNotEmpty)
        .toList();
    // If no structured sentence that uses the BNF
    if (matchedTokens.isEmpty) {
      throw ArgumentError("Enter a valid sentence!");
    }
    // Starts with ON
    if (!matchedTokens.first.contains('ON')) {
      throw ArgumentError("Sentence must start with 'ON'.");
    }
    // Ends with OFF
    if (!matchedTokens.last.contains('OFF')) {
      throw ArgumentError("Sentence must end with 'OFF'.");
    }
    matchedTokens.removeAt(0); // Remove 'ON'
    matchedTokens.removeLast(); // Remove 'OFF'
    // Check for instructions between ON and OFF and for extra delimiters
    if (matchedTokens.isEmpty) {
      throw FormatException(
          "Sentence must contain valid instructions between 'ON' and 'OFF'.");
    } else {
      if (matchedTokens.first == "-") {
        // first token a delimeter
        throw FormatException(
            "Invalid instruction format: The first valid token cannot be a delimiter.");
      } else if (matchedTokens.last == "-") {
        // last token a delimeter
        throw FormatException(
            "Invalid instruction format: The last valid token cannot be a delimiter.");
      } else {
        for (int i = 0; i < matchedTokens.length; i++) {
          // check for consecutive delimeters
          if (matchedTokens[i] == "-" &&
              (i > 0 && matchedTokens[i - 1] == "-")) {
            throw ArgumentError(
                "Invalid instruction format: Cannot have two consecutive '-'.");
          }
        }
      }
    }
    // Remove Delimeters
    matchedTokens.removeWhere((element) => RegExp(r'-').hasMatch(element));
    derivationSteps.add("ON <instructions> OFF");
    // derive the valid instructions
    return deriveInstructions(matchedTokens);
  } catch (e) {
    throw e;
  }
}

// Function to format the derivation Steps
void showDerivation() {
  print(
      '${' '.padRight(5)} ${'<proc>'.padRight(15)} ${'➝'.padRight(15)} ${derivationSteps[0]}');
  for (int i = 1; i < derivationSteps.length; i++) {
    String stepNumber = (i + 1).toString().padLeft(2, '0');
    print(
        '${stepNumber.padRight(5)} ${' '.padRight(15)} ${'➝'.padRight(15)} ${derivationSteps[i]}');
  }
}

// Parse Tree
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
  } else
    print("Error: Invalid structure.");
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
    if (i < lines.length - 1) print(" │    ├── -");
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
  } else
    print("Error: Invalid line structure.");
}

// Helper function to draw the <xy> for each coordinate
void drawXY(String xy, int index) {
  String x = xy[0];
  String y = xy[1];
  print(" │    │    ├── <xy> $index");
  print(" │    │    │    ├── <x> $x");
  print(" │    │    │    └── <y> $y");
}

/**
 * Main
 */
void main() {
  while (true) {
    try {
      displayGrammar();
      String userInput = myInput("Enter your sentence:  ") ?? "";

      if (!checkHalt(userInput)) {
        if (attemptDerivation(userInput)) {
          showDerivation();
          myInput("Press any enter to continue: ");
          drawParseTree(userInput);
        }
      } else {
        printCharacters("\nTerminating Program", "-");
        break;
      }
    } catch (e) {
      print(e);
    }
  }
}
