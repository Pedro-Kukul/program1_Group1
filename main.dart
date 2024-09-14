import 'dart:io';

void main() {
  while (true) {
    // Display the BNF Grammar
    displayGrammar();

    // Accept user input
    stdout.write("Enter the input string (or type 'HALT' to stop): ");
    String input = stdin.readLineSync() ?? '';

    if (input.toUpperCase() == 'HALT') {
      print("Program terminated.");
      break;
    }

    // Attempt rightmost derivation
    if (recognizeLanguage(input)) {
      print("String recognized successfully!");
      drawParseTree(input);
    } else {
      print("Error: The string is not recognized by the grammar.");
    }

    print("\n"); // Add a newline for readability between iterations
  }
}

// Function to display the BNF grammar
void displayGrammar() {
  print('''
BNF Grammar:
<proc> → ON <body> OFF
<instructions> → <line>
               | <line> - <instructions>
<line> → sqr <xy>,<xy>
       | tri <xy>,<xy>,<xy>
<xy> → <x><y>
<x> → a | b | c | d | e | f
<y> → 1 | 2 | 3 | 4 | 5 | 6
  ''');
}

// Function to check if the input string matches the grammar
bool recognizeLanguage(String input) {
  final pattern = RegExp(
      r'^ON (sqr [a-f][1-6],[a-f][1-6]( - )?|(tri [a-f][1-6],[a-f][1-6],[a-f][1-6]( - )?)*)+ OFF$');

  return pattern.hasMatch(input);
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
