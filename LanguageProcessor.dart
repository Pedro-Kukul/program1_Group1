import 'dart:io';

final List<List<String>> grammar = [
  ['<proc>', '➝', '', 'ON <instructions> OFF'],
  ['<instructions>', '➝', '', '<line>'],
  ['', '', '|', '<line> - <instructions>'],
  ['<line>', '➝', '', 'sqr <xy>,<xy>'],
  ['', '', '|', 'tri <xy>,<xy>,<xy>'],
  ['<xy>', '➝', '', '<x><y>'],
  ['<x>', '➝', '', 'a | b | c | d | e | f'],
  ['<y>', '➝', '', '1 | 2 | 3 | 4 | 5 | 6 |']
];

// Print at center
void printCharacters(String message, String symbol) {
  int totalColumns = stdout.terminalColumns;
  double symbolCount = totalColumns / 2 - message.length / 2;
  if (symbolCount > 0) {
    print(symbol.padLeft(symbolCount.toInt(), symbol) +
        message +
        symbol.padRight(symbolCount.toInt(), symbol));
  }
}

// Display Grammar
void displayGrammar() {
  double center = stdout.terminalColumns / 2 - 10;
  printCharacters(" Grammar ", "-");
  for (var line in grammar) {
    print(
        '${line[0].padLeft(center.toInt()).padRight(15)} ${line[1].padRight(10)} ${line[2].padRight(1)} ${line[3]}');
  }
  printCharacters("", "-");
}

// Grammer
final String bnf_Process = "ON <instructions> OFF";
final String bnf_Instructions = "<instructions>";
final String bnf_Instructions2 = "<line> - <instructions>";
final String bnf_Line = "<line>";
final String bnf_sqr = "sqr <xy>,<xy>";
final String bnf_tri = "tri <xy>,<xy>,<xy>";
final String bnf_coordinates = "<xy>";
final String bnf_xy = "<x><y>";
final String bnf_x = "<x>";
final String bnf_y = "<y>";

// Regex
final r_halt = RegExp(r'^HALT$'); // Termination
final r_ON = RegExp(r'^ON$', caseSensitive: true);
final r_OFF = RegExp(r'^OFF$', caseSensitive: true);
final r_Delimeter = RegExp(r'-');
final r_Shape = RegExp(r'tri|sqr');
final r_Tri = RegExp(r'^tri$');
final r_Sqr = RegExp(r'^sqr$');
final r_Coordinates = RegExp(r'[a-z]\d+(?:,[a-z]\d+){1,2}');
final r_SingleCoordinate = RegExp(r'^[a-zA-Z]\d$');
final r_X = RegExp(r'[a-f]');
final r_Y = RegExp(r'[1-6]');

// For formatting purposes
int counter = 1;
// Holds derivation steps
List<String> derivationSteps = [];
List<String> linesToDerive = [];

void updateDerivationSteps(String target, String replacement) {
  if (derivationSteps.isEmpty) return; // Return if empty
  String lastStep = derivationSteps.last; // Last derivation step
  // Rightmost target
  int lastIndex = lastStep.lastIndexOf(target);
  if (lastIndex != -1) {
    counter++;
    derivationSteps.add(lastStep.replaceRange(
        lastIndex, lastIndex + target.length, replacement));
    print(
        '${counter.toString().padLeft(2, '0').padRight(5)} ${' '.padRight(15)} ${'➝'.padRight(15)} ${derivationSteps.last}');
  }
}

void rightMostDerivation(String input) {
  derivationSteps.clear();
  linesToDerive.clear();
  counter = 1;

  // if no process throw an error message
  if (input.isEmpty) throw "Enter a process!";

  //Remove whitespace
  List<String> processList = input.trim().split(RegExp(r"\s+"));

  // if prcoess does not end with 'OFF', then throw an error
  if (!r_OFF.hasMatch(processList.last))
    throw "Sentence must end with OFF received: ${processList.last}!";
  // If the process does not start with 'ON', throw an error
  if (!r_ON.hasMatch(processList.first))
    throw "Sentence must begin with ON recieved: ${processList.first}!";
  // add the first step of derivation since the function has recieved a sentence that start with 'ON' and 'OFF'
  derivationSteps.add(bnf_Process);
  print(
      '${' '.padRight(5)} ${'<proc>'.padRight(15)} ${'➝'.padRight(15)} ${derivationSteps[0]}');
  // Remove the first and last ON and OFF
  processList.removeAt(0);
  processList.removeLast();

  // Check if more ons and offs were included
  if (processList.contains(r_OFF.pattern)) throw "Multiple OFF not allowed";
  if (processList.contains(r_ON.pattern)) throw "Multiple ON not allowed!";

  // If nothing other than ON and OFF were entered then throw error
  if (processList.isEmpty) throw "Enter instructions!";
  // Move on to Process Instructions
  deriveInstructions(processList);
  printCharacters("Derivation Complete", "-");
}

bool deriveInstructions(List<String> instructions) {
  // If empty, return false
  if (instructions.isEmpty) return false;

  // Check if the first or last element is a delimiter and throw an error with position
  if (r_Delimeter.hasMatch(instructions.first))
    throw "Delimiter '-' cannot be at the beginning (${instructions.join(" ")})";
  if (r_Delimeter.hasMatch(instructions.last))
    throw "Delimiter '-' cannot be at the end (${instructions.join(" ")})";

  // Get the last index of the delimiter
  int lastSymbolIndex = instructions.indexOf(r_Delimeter.pattern);

  // If delimiter is found in the list
  if (lastSymbolIndex != -1) {
    // Create the instruction string from the sublist to the right of the symbol (inclusive)
    updateDerivationSteps(bnf_Instructions, bnf_Instructions2);
    // Add to a list
    linesToDerive.add(instructions.sublist(0, lastSymbolIndex).join(" "));
    // Remove the sublist from the original instructions list
    instructions.removeRange(0, lastSymbolIndex + 1);
    // Recursively process the remaining instructions
    return deriveInstructions(instructions);
  }
  updateDerivationSteps(bnf_Instructions, bnf_Line);
  linesToDerive.add(instructions.sublist(0).join(" "));
  return deriveLines(linesToDerive);
}

bool deriveLines(List<String> linesList) {
  if (linesList.isEmpty) return false;
  String line = linesList.removeLast().trim();
  List<String> lineComponents = line.split(RegExp(r"[\s]+"));
  int expectedCoordinates;

  // Ensure there are exactly two components: shape and coordinates

  if (lineComponents.length > 2) {
    throw "Invalid Line: $line. Extra components detected: ${lineComponents.sublist(2).join(" ")}";
  }

  // Check if the first component is a valid shape
  if (r_Tri.hasMatch(lineComponents[0])) {
    updateDerivationSteps(bnf_Line, bnf_tri);
    expectedCoordinates = 3;
  } else if (r_Sqr.hasMatch(lineComponents[0])) {
    updateDerivationSteps(bnf_Line, bnf_sqr);
    expectedCoordinates = 2;
  } else
    throw "Invalid Line: $line. ${lineComponents[0]} is not a valid shape";

  if (lineComponents.length == 1)
    throw "Invalid Line: $line. Missing coordinates for shape ${lineComponents[0]}";

  // Check if the second component (coordinates) is valid
  if (!r_Coordinates.hasMatch(lineComponents[1]))
    throw "Invalid Line: $line. Invalid Coordinates Format: ${lineComponents[1]}";
  // Derive coordinates
  List<String> coordinatesList = lineComponents[1].trim().split(",");
  if (coordinatesList.length != expectedCoordinates) {
    throw ("Expected $expectedCoordinates coordinates for shape ${lineComponents[0]} at $line, received ${coordinatesList.join(",")}");
  }
  deriveCoordinates(coordinatesList);

  return deriveLines(linesList);
}

bool deriveCoordinates(List<String> coordinates) {
  if (coordinates.isEmpty) return false;
  String coordinate = coordinates.removeLast().trim();
  if (!r_SingleCoordinate.hasMatch(coordinate))
    throw "Invalid Coordinate: Expected XY. Recieved: $coordinate";
  updateDerivationSteps(bnf_coordinates, bnf_xy);
  deriveXY(coordinate);
  return deriveCoordinates(coordinates);
}

void deriveXY(String coord) {
  String xComponent = coord[0];
  String yComponent = coord[1];
// Derive Y
  if (r_Y.hasMatch(yComponent))
    updateDerivationSteps(bnf_y, yComponent);
  else
    throw "Expected 1-6, received: $yComponent at $coord";
  updateDerivationSteps(bnf_xy, bnf_y);
  if (r_X.hasMatch(xComponent))
    updateDerivationSteps(bnf_x, xComponent);
  // Derive X
  else
    throw "Expected X  a-f, received: $xComponent at $coord";
  updateDerivationSteps(bnf_xy, bnf_x);
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

void main() {
  while (true) {
    try {
      displayGrammar();
      stdout.write("Enter a string: ".padLeft(20));
      String input = stdin.readLineSync() ?? "";
      if (!checkHalt(input)) {
        rightMostDerivation(input);
      } else {
        printCharacters("\nTerminating Program", "-");
        break;
      }
    } catch (e) {
      print(e);
    }
  }
}
