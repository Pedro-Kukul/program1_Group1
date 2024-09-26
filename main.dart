import 'dart:convert';
import 'dart:io';

List<String> lines = [];
// Regex
// final r_halt = RegExp(r'^HALT$');
// final r_on = RegExp(r"^ON");
// final r_off = RegExp(r"OFF$");

// final r_shape = RegExp(r"sqr|tri");
// final r_coord = RegExp(r"([a-f][1-6]),([a-f][1-6])(,([a-f][1-6]))?");
// final r_x = RegExp(r"[a-f]");
// final r_y = RegExp(r"[1-6]");
final r_sqr = RegExp(r'sqr\s+[a-z]+\d{1,2}(?:,[a-z]+\d{1,2})');
final r_tri = RegExp(r"tri\s+[a-z]+\d{1,2}(?:,[a-z]+\d{1,2}){2}");
final r_delim = RegExp(r"-");

final r_halt = RegExp(r'^HALT$');
final r_on = RegExp(r"^ON");
final r_off = RegExp(r"OFF$"); // final r_instructions = RegExp(
//     r'^\s*ON\s*(?:[a-zA-Z]{3}\s+[a-z]+\d{1,2}(?:,[a-z]+\d{1,2}){1,2}(?:\s*-\s*[a-zA-Z]{3}\s+[a-z]+\d{1,2}(?:,[a-z]+\d{1,2}){1,2})*)?\s*OFF$');

final r_line =
    RegExp(r'^(?:-)?[a-zA-Z]{3}\s+[a-z]+\d{1,2}(?:,[a-z]+\d{1,2}){1,2}$');

final r_shape = RegExp(
    r'\s*(?:tri\s+[a-z]+\d{1,2}(?:,[a-z]+\d{1,2}){2}|sqr\s+[a-z]+\d{1,2}(?:,[a-z]+\d{1,2}))');

final r_single_coordinate = RegExp(r'[a-z]\d+');
final r_x = RegExp(r'[a-f]');
final r_y = RegExp(r'[1-6]');

// Function to replace the rightmost occurrence of a target substring
String replaceRightMost(String str, String target, String replacement) {
  int lastIndex = str.lastIndexOf(target);
  if (lastIndex == -1)
    return str; // If target not found, return original string
  return str.replaceRange(lastIndex, lastIndex + target.length, replacement);
}

void updateDerivationSteps(String target, String replacement) {
  if (derivationSteps.isEmpty) return; // Check if there are steps to update
  String lastStep = derivationSteps.last; // Get the last derivation step
  int lastIndex = lastStep.lastIndexOf(target);

  if (lastIndex != -1) {
    String updatedStep = lastStep.replaceRange(
        lastIndex, lastIndex + target.length, replacement);
    derivationSteps.add(updatedStep);
  }
}

// Helper Function to print a message
Future<void> myPrint(String output) async {
  stdout.write(output);
}

// Helper function to recieve input
String? myInput(String prompt) {
  myPrint("\n" + prompt);
  return stdin.readLineSync(encoding: utf8);
}

// Helper function to print a line of characters
void printCharacters(String message, String symbol) {
  int totalColumns = stdout.terminalColumns;
  int symbolCount = totalColumns - message.length;

  if (symbolCount > 0) {
    print("\n" + message + symbol.padRight(symbolCount, symbol));
  }
}

// Check for HALT to terminate program
bool checkHalt(String input) {
  if (r_halt.hasMatch(input)) {
    return true;
  } else if (r_halt.hasMatch(input.toUpperCase())) {
    // Input matches 'HALT' in any case (e.g., halt, Halt, hALt)
    throw ArgumentError("Did you mean HALT?");
  }
  return false;
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
  print("Grammar:");
  for (var line in grammar) {
    print(
        '${line[0].padRight(15)} ${line[1].padRight(10)} ${line[2].padRight(1)} ${line[3]}');
  }
}

// List to hold the steps for derivation
List<String> derivationSteps = [];
List<String> checkedList = [];

// Y then x
bool processXY(List<String> tokenList) {
  if (tokenList.isEmpty) return false;
  try {
    String component = tokenList.removeLast();
    if (RegExp(r"[0-9]").hasMatch(component)) {
      if (r_y.hasMatch(component)) {
        updateDerivationSteps("<y>", component);
      } else {
        throw ArgumentError("Expected [1-6] Recieved $component");
      }
    } else if (RegExp(r"[a-z]").hasMatch(component)) {
      if (r_x.hasMatch(component)) {
        updateDerivationSteps("<x>", component);
      } else {
        throw ArgumentError("I expexted [a-f] received $component");
      }
    }
    return processXY(tokenList);
  } catch (e) {
    throw e;
  }
}

bool processCoordinates(List<String> tokenList) {
  if (tokenList.isEmpty) return false;
  try {
    String coordinate = tokenList.removeLast();
    if (r_single_coordinate.hasMatch(coordinate)) {
      updateDerivationSteps("<xy>", "<x><y>");
      List<String> components = coordinate.split("");
      processXY(components);
    } else {
      throw ArgumentError("Error Procesing coordinate: $coordinate");
    }
    return processCoordinates(tokenList);
  } catch (e) {
    throw e;
  }
}

bool processLines(List<String> tokenList) {
  if (tokenList.isEmpty) return false;
  try {
    String line = tokenList.removeAt(0);
    if (r_tri.hasMatch(line)) {
      updateDerivationSteps("<line>", "tri <xy>,<xy>,<xy>");
    } else if (r_sqr.hasMatch(line)) {
      updateDerivationSteps("<line>", "sqr <xy>,<xy>");
    } else {
      throw ArgumentError("Error Processing: $line is not a valid shape");
    }

    Iterable<RegExpMatch> matches = r_single_coordinate.allMatches(line);
    List<String> coordinatesList = [];
    for (var match in matches) {
      coordinatesList.add(match.group(0)!);
    }
    processCoordinates(coordinatesList);
    return processLines(tokenList);
  } catch (e) {
    throw e;
  }
}

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
    throw FormatException("Error processing instructions: ${e}");
  }
}

// The baddes bitch in the program
bool attemptDerivation(String input) {
  // final r_instructions = RegExp(
  //     r'(?:-)?\s*(?:[a-zA-Z]{3}|ON|OFF)\s+[a-z]+\d{1,2}(?:,[a-z]+\d{1,2}){1,2}|\bON\b|\bOFF\b');
  final r_instructions = RegExp(r"ON|OFF|([a-zA-Z]{3})\s+([a-zA-Z]\d+,?)+|-");

  final r_on = RegExp(r'\bON\b');
  final r_off = RegExp(r'\bOFF\b');
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

    // send only the shapes to process
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
      printCharacters("", "-");
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

/**
 * INPUT = ON sqr a1,a2 - tri b1,b2,b3 - tri c1,c2,c3 - sqr d1,d2 - tri b1,b2,b3 - tri c1,c2,c3 - sqr d1,d2 - tri c1,c2,c3 - sqr d1,d2 - tri b1,b2,b3 - tri c1,c2,c3 - sqr d1,d2 - tri c1,c2,c3 - sqr d1,d2 - tri b1,b2,b3 - tri c1,c2,c3 - sqr d1,d2 - tri c1,c2,c3 - sqr d1,d2 - tri b1,b2,b3 - tri c1,c2,c3 - sqr d1,d2 - tri c1,c2,c3 - sqr d1,d2 - tri b1,b2,b3 - tri c1,c2,c3 - sqr d1,d2 - tri c1,c2,c3 - sqr d1,d2 - tri b1,b2,b3 - tri c1,c2,c3 - sqr d1,d2 - tri c1,c2,c3 - sqr d1,d2 - tri b1,b2,b3 - tri c1,c2,c3 - sqr d1,d2 - tri c1,c2,c3 - sqr d1,d2 - tri b1,b2,b3 - tri c1,c2,c3 - sqr d1,d2 - tri c1,c2,c3 - sqr d1,d2 - tri b1,b2,b3 - tri c1,c2,c3 - sqr d1,d2 - tri c1,c2,c3 - sqr d1,d2 - tri b1,b2,b3 - tri c1,c2,c3 - sqr d1,d2 - tri c1,c2,c3 - sqr d1,d2 - tri b1,b2,b3 - tri c1,c2,c3 - sqr d1,d2 - tri c1,c2,c3 - sqr d1,d2 - tri b1,b2,b3 - tri c1,c2,c3 - sqr d1,d2 - tri c1,c2,c3 - sqr d1,d2 - tri b1,b2,b3 - tri c1,c2,c3 - sqr d1,d2 - tri c1,c2,c3 - sqr d1,d2 - tri b1,b2,b3 - tri c1,c2,c3 - sqr d1,d2 - tri c1,c2,c3 - sqr d1,d2 - tri b1,b2,b3 - tri c1,c2,c3 - sqr d1,d2 - tri c1,c2,c3 - sqr d1,d2 - tri b1,b2,b3 - tri c1,c2,c3 - sqr d1,d2 - tri c1,c2,c3 - sqr d1,d2 - tri b1,b2,b3 - tri c1,c2,c3 - sqr d1,d2 OFF
 * ON <instructions> OFF
 * ON <line> - <instructions> OFF
 * ON <line> - <line> - <instructions> OFF
 * ON <line> - <line> - <line> - <instructions> OFF
 * ON <line> - <line> - <line> - <line> OFF
 * ON <line> - <line> - <line> - sqr <xy>,<xy> OFF
 * ON <line> - <line> - <line> - sqr <xy>,<x><y> OFF
 * ON <line> - <line> - <line> - sqr <xy>,<x>2 OFF
 * ON <line> - <line> - <line> - sqr <xy>,d2 OFF
 * ON <line> - <line> - <line> - sqr <x><y>,d2 OFF
 * ON <line> - <line> - <line> - sqr <x>1,d2 OFF
 * ON <line> - <line> - <line> - sqr d1,d2 OFF
 * ON <line> - <line> - tri <xy>,<xy>,<xy> - sqr d1,d2 OFF
 * ON <line> - <line> - tri <xy>,<xy>,<x><y> - sqr d1,d2 OFF
 * ON <line> - <line> - tri <xy>,<xy>,<x>3 - sqr d1,d2 OFF
 * ON <line> - <line> - tri <xy>,<xy>,c3 - sqr d1,d2 OFF
 * ON <line> - <line> - tri <xy>,<x><y>,c3 - sqr d1,d2 OFF
 * ON <line> - <line> - tri <xy>,<x>2,c3 - sqr d1,d2 OFF
 * ON <line> - <line> - tri <xy>,c2,c3 - sqr d1,d2 OFF
 * ON <line> - <line> - tri <x><y>,c2,c3 - sqr d1,d2 OFF
 * ON <line> - <line> - tri <x>1,c2,c3 - sqr d1,d2 OFF
 * ON <line> - <line> - tri c1,c2,c3 - sqr d1,d2 OFF
 * ON <line> - tri <xy>,<xy>,<xy> - tri c1,c2,c3 - sqr d1,d2 OFF
 * ON <line> - tri <xy>,<xy>,<x><y> - tri c1,c2,c3 - sqr d1,d2 OFF
 * ON <line> - tri <xy>,<xy>,<x>3 - tri c1,c2,c3 - sqr d1,d2 OFF
 * ON <line> - tri <xy>,<xy>,b3 - tri c1,c2,c3 - sqr d1,d2 OFF
 * ON <line> - tri <xy>,<x><y>,b3 - tri c1,c2,c3 - sqr d1,d2 OFF
 * ON <line> - tri <xy>,<x>2,b3 - tri c1,c2,c3 - sqr d1,d2 OFF
 * ON <line> - tri <xy>,b2,b3 - tri c1,c2,c3 - sqr d1,d2 OFF
 * ON <line> - tri <x><y>,b2,b3 - tri c1,c2,c3 - sqr d1,d2 OFF
 * ON <line> - tri <x>1,b2,b3 - tri c1,c2,c3 - sqr d1,d2 OFF
 * ON <line> - tri b1,b2,b3 - tri c1,c2,c3 - sqr d1,d2 OFF
 * ON sqr <xy>,<xy> - tri b1,b2,b3 - tri c1,c2,c3 - sqr d1,d2 OFF
 * ON sqr <xy>,<x><y> - tri b1,b2,b3 - tri c1,c2,c3 - sqr d1,d2 OFF
 * ON sqr <xy>,<x>2 - tri b1,b2,b3 - tri c1,c2,c3 - sqr d1,d2 OFF
 * ON sqr <xy>,a2 - tri b1,b2,b3 - tri c1,c2,c3 - sqr d1,d2 OFF
 * ON sqr <x><y>,a2 - tri b1,b2,b3 - tri c1,c2,c3 - sqr d1,d2 OFF
 * ON sqr <x>1,a2 - tri b1,b2,b3 - tri c1,c2,c3 - sqr d1,d2 OFF
 * ON sqr a1,a2 - tri b1,b2,b3 - tri c1,c2,c3 - sqr d1,d2 OFF
 */