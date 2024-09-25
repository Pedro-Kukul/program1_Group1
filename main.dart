import 'dart:convert';
import 'dart:io';

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
// final r_delim = RegExp(r"-");

final r_halt = RegExp(r'^HALT$');
final r_on = RegExp(r"^ON");
final r_off = RegExp(r"OFF$");
final r_instructions = RegExp(
    r'(?:-)?\s*(?:[a-zA-Z]{3}|ON|OFF)\s+[a-z]+\d{1,2}(?:,[a-z]+\d{1,2}){1,2}|\bON\b|\bOFF\b');
// final r_instructions = RegExp(
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

bool processX(List<String> tokenList) {
  try {
    // converts the last coordinate into its <x> its actual value
    // tokenizes this last line
    // calls the processy function
    // removes the line from the tokenlist
    // calls the processCoordinates function
  } catch (e) {
    throw e;
  }
  return true;
}

bool processY(List<String> tokenList) {
  try {
    // converts the last coordinate into its <x><y>
    // tokenizes this last line
    // calls the processX function
    // removes the line from the tokenlist
    // calls the function
  } catch (e) {
    throw e;
  }
  return true;
}

bool processCoordinates(List<String> tokenList) {
  try {
    if (tokenList.isEmpty) return false;

    for (var coord in tokenList.reversed) {
      if (r_single_coordinate.hasMatch(coord)) {
        String lastStep = derivationSteps.last;
        derivationSteps.add(replaceRightMost(lastStep, "<xy>", "<x><y>"));
        List<String> components = coord.split("");
        for (var component in components.reversed) {
          if (r_y.hasMatch(component)) {
            String lastStep = derivationSteps.last;
            derivationSteps.add(replaceRightMost(lastStep, "<y>", component));
          } else if (r_x.hasMatch(component)) {
            String lastStep = derivationSteps.last;
            derivationSteps.add(replaceRightMost(lastStep, "<x>", component));
          } else {
            throw ArgumentError("I love myself");
          }
        }
      } else {
        throw ArgumentError("alahu akhbar");
      }
    }
    // converts the last coordinate into its <x><y>
    // tokenizes this last line
    // calls the processy function
    // removes the line from the tokenlist
    // calls the processLinesFunction function
  } catch (e) {
    throw e;
  }
  return true;
}

bool processLines(List<String> tokenList) {
  try {
    if (tokenList.isEmpty) return false;

    for (var line in tokenList) {
      List<String> cleanedTokensList = [];
      String lastStep = derivationSteps.last;
      if (r_tri.hasMatch(line)) {
        derivationSteps
            .add(replaceRightMost(lastStep, "<line>", "tri <xy>,<xy>,<xy>"));
      } else if (r_sqr.hasMatch(line)) {
        derivationSteps
            .add(replaceRightMost(lastStep, "<line>", "sqr <xy>,<xy>"));
      } else {
        throw ArgumentError("Something went wrong");
      }
      Iterable<RegExpMatch> matches = r_single_coordinate.allMatches(line);
      for (var match in matches) {
        cleanedTokensList.add(match.group(0)!); // Add the matched <xy> value
      }
      processCoordinates(cleanedTokensList);
    }
  } catch (e) {
    throw e;
  }
  return true;
}

// accepts a token list of xyLines and deliiters
// derives all instructions into lines first
// upon completion or when no more additional instructions will remove all delimeters from the tokenlist and calls the process lines function
bool processInstructions(List<String> tokenList) {
  try {
    List<String> cleanedTokensList = [];

    for (var token in tokenList.reversed) {
      String lastStep = derivationSteps.last;

      if (token.contains('-')) {
        // Split token by the delimiter '-' and process both parts
        List<String> parts =
            token.split('-').map((part) => part.trim()).toList();

        // Validate both parts of the token (if applicable)
        if (parts.length == 2 && r_line.hasMatch(parts[1])) {
          derivationSteps.add(replaceRightMost(
              lastStep, "<instructions>", "<line> - <instructions>"));
          // derivationSteps.add(lastStep.replaceFirst(
          //     "<instructions>", "<line> - <instructions>"));
          cleanedTokensList.add(parts[1]);
        } else {
          throw FormatException("Invalid format in token: $token");
        }
      } else {
        // If token doesn't have a delimiter, just process the line
        if (r_line.hasMatch(token)) {
          derivationSteps
              .add(lastStep.replaceFirst("<instructions>", "<line>"));
          cleanedTokensList.add(token);
        } else {
          throw FormatException("Invalid format in token: $token");
        }
      }
    }
    processLines(cleanedTokensList);
    return true;
  } catch (e) {
    throw FormatException("Error processing instructions: $e");
  }
}

bool attemptDerivation(String input) {
  try {
    input.trim();
    // Error Correction
    if (input.isEmpty) {
      throw ArgumentError("Enter a sentence!");
    } else if (!r_on.hasMatch(input)) {
      throw ArgumentError("Sentence must start with 'ON'");
    } else if (!r_off.hasMatch(input)) {
      throw ArgumentError("Sentence must end with 'OFF'");
    }
    derivationSteps.clear();

    // Tokenize the string
    Iterable<RegExpMatch> matches = r_instructions.allMatches(input);
    List<String> tokenList = matches
        .map((match) => match.group(0)!.trim())
        .where((element) => element.isNotEmpty)
        .toList();

// If empty thhrow tha btich
    if (tokenList.isEmpty) {
      throw FormatException("No valid tokens found.");
    }
    // could have really just been a simple thing but no
    String concatenatedResult = tokenList.first;
    // Create new list that excludes "ON" and "OFF"
    // I hate myself
    List<String> middleTokens =
        tokenList.where((i) => i != "ON" && i != "OFF").toList();

    if (tokenList.every((token) => token == "ON" || token == "OFF")) {
      throw FormatException("Invalid tokens found in the list.");
    } else {
      concatenatedResult += " <instructions>";
    }

    concatenatedResult += " " + tokenList.last;

    derivationSteps.add(concatenatedResult);
    if (!processInstructions(middleTokens)) {
      return false;
    }
    return true;
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

class Node {
  String value;
  List<Node> children = [];

  Node(this.value);

  void addChild(Node child) {
    children.add(child);
  }

  // Print the parse tree recursively with lines going down
  void printTree({String prefix = '', bool isLast = true}) {
    // Print the current node value
    print('${prefix}${value}');

    // Adjust the prefix for the next level of children
    String newPrefix = prefix + (isLast ? '    ' : ' |  ');

    // Print each child recursively
    for (int i = 0; i < children.length; i++) {
      bool lastChild = i == children.length - 1;
      String childPrefix = newPrefix + (lastChild ? ' └── ' : ' ├── ');

      children[i].printTree(prefix: childPrefix, isLast: lastChild);
    }
  }
}

// Function to build the parse tree for a derivation
Node buildParseTree(List<String> tokenList) {
  Node root = Node('<proc>');

  // Add the ON and OFF tokens manually
  Node instructionsNode = Node('<instructions>');
  root.addChild(Node('ON'));
  root.addChild(instructionsNode);
  root.addChild(Node('OFF'));

  // Recursively process the tokens to build the parse tree
  processInstructionsForTree(tokenList, instructionsNode);

  return root;
}

// Recursive function to process instructions for parse tree
void processInstructionsForTree(List<String> tokenList, Node parentNode) {
  if (tokenList.isEmpty) return;

  if (tokenList.contains('-')) {
    int index = tokenList.indexOf('-');
    List<String> firstPart = tokenList.sublist(0, index);
    List<String> secondPart = tokenList.sublist(index + 1);

    // Create <line> - <instructions> structure
    Node lineNode = Node('<line>');
    parentNode.addChild(lineNode);
    processLineForTree(firstPart, lineNode);

    Node delimNode = Node('-');
    parentNode.addChild(delimNode);

    Node instructionsNode = Node('<instructions>');
    parentNode.addChild(instructionsNode);
    processInstructionsForTree(secondPart, instructionsNode);
  } else {
    Node lineNode = Node('<line>');
    parentNode.addChild(lineNode);
    processLineForTree(tokenList, lineNode);
  }
}

// Function to process a line for the parse tree
void processLineForTree(List<String> tokenList, Node parentNode) {
  if (tokenList.isEmpty) return;

  if (r_sqr.hasMatch(tokenList.first)) {
    parentNode.addChild(Node('sqr'));
    Node xyNode1 = Node(tokenList[1]); // First xy
    parentNode.addChild(xyNode1);

    Node xyNode2 = Node(tokenList[2]); // Second xy
    parentNode.addChild(xyNode2);
  } else if (r_tri.hasMatch(tokenList.first)) {
    parentNode.addChild(Node('tri'));
    Node xyNode1 = Node(tokenList[1]); // First xy
    parentNode.addChild(xyNode1);

    Node xyNode2 = Node(tokenList[2]); // Second xy
    parentNode.addChild(xyNode2);

    Node xyNode3 = Node(tokenList[3]); // Third xy
    parentNode.addChild(xyNode3);
  }
}

// Call this function to display the parse tree
void showParseTree(String input) {
  input = input.trim();
  List<String> tokenList = input.split(RegExp(r"\s*[,]\s*|\s+"));

  // Remove 'ON' and 'OFF'
  tokenList.removeAt(0);
  tokenList.removeLast();

  // Build and print the parse tree
  Node parseTree = buildParseTree(tokenList);
  print("\nParse Tree:\n");
  parseTree.printTree();
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
        showParseTree(userInput);
      }
    } catch (e) {
      print(e);
    }
  }
}

/**
 * INPUT = ON sqr a1,a2 - tri b1,b2,b3 - tri c1,c2,c3 - sqr d1,d2 OFF
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
