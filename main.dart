import 'dart:io';

//MAIN is all the way at the bottom!

// Function to perform rightmost derivation
List<String> rightmostDerivation(String input) {
  List<String> sententialForms = [];
  sententialForms.add('<proc>');

  // Get the list of coordinates from the input string
  List<String> coordinates = input.split(RegExp(r'[,\s]'))
      .where((part) => RegExp(r'^[a-f][1-6]$').hasMatch(part))
      .toList();
  int coordIndex = 0;

  try {
    while (sententialForms.last != input) {
      String current = sententialForms.last;
      String nextForm = current;

      // Perform the rightmost derivation
      if (current.contains('<proc>')) {
        nextForm = nextForm.replaceFirst('<proc>', 'ON <body> OFF');
      } else if (current.contains('<body>')) {
        nextForm = nextForm.replaceFirst('<body>', '<instructions>');
      } else if (current.contains('<instructions>')) {
        if (input.split(' - ').length > 1 && !current.contains('<line>')) {
          nextForm = nextForm.replaceFirst('<instructions>', '<line> - <instructions>');
        } else {
          nextForm = nextForm.replaceFirst('<instructions>', '<line>');
        }
      } else if (current.contains('<line>')) {
        if (input.contains('sqr')) {
          nextForm = nextForm.replaceFirst('<line>', 'sqr <xy>,<xy>');
        } else if (input.contains('tri')) {
          nextForm = nextForm.replaceFirst('<line>', 'tri <xy>,<xy>,<xy>');
        } else {
          throw Exception('Invalid input: expected sqr or tri');
        }
      } else if (current.contains('<xy>')) {
        if (coordIndex >= coordinates.length) {
          throw Exception('Not enough coordinates provided in the input');
        }
        nextForm = nextForm.replaceFirst('<xy>', coordinates[coordIndex]);
        coordIndex++;
      }

      // If the next form is the same as the current form, then we have reached
      // a dead end and must throw an exception
      if (nextForm == current) {
        throw Exception('Unable to derive next form: $current');
      }

      sententialForms.add(nextForm);
    }

    return sententialForms;
  } catch (e) {
    throw Exception('Error during derivation: $e');
  }
}

// Class to represent a node in the parse tree
class Node {
  String value;
  List<Node> children;

  Node(this.value, [List<Node>? children]) : children = children ?? [];

  void addChild(Node child) {
    children.add(child);
  }
}
// Function to build the parse tree
Node buildParseTree(String sententialForm) {
  List<String> tokens = sententialForm.split(' ');
  Node root = Node('proc');
  Node current = root;

  for (String token in tokens) {
    if (token == 'ON') {
      current.addChild(Node('ON'));
    } else if (token == 'OFF') {
      current.addChild(Node('OFF'));
      current = root;
    } else if (token == 'sqr' || token == 'tri') {
      Node lineNode = Node('line');
      lineNode.addChild(Node(token));
      current.addChild(lineNode);
      current = lineNode;
    } else if (RegExp(r'^[a-f][1-6]$').hasMatch(token)) {
      Node xyNode = Node('xy');
      xyNode.addChild(Node('x', [Node(token[0])]));
      xyNode.addChild(Node('y', [Node(token[1])]));
      current.addChild(xyNode);
    } else if (token.contains(',')) {
      // Handle multiple coordinates
      List<String> coords = token.split(',');
      for (String coord in coords) {
        if (RegExp(r'^[a-f][1-6]$').hasMatch(coord)) {
          Node xyNode = Node('xy');
          xyNode.addChild(Node('x', [Node(coord[0])]));
          xyNode.addChild(Node('y', [Node(coord[1])]));
          current.addChild(xyNode);
        }
      }
    }
  }

  return root;
}

// Helper functions to build the parse tree
Node buildBodyNode(String body) {
  Node bodyNode = Node('body');
  bodyNode.children.add(buildInstructionsNode(body));
  return bodyNode;
}

//  Helper functions to build the parse tree
Node buildInstructionsNode(String instructions) {
  Node instructionsNode = Node('instructions');
  List<String> lines = instructions.split(' - ');

  for (String line in lines) {
    instructionsNode.children.add(buildLineNode(line));
  }

  return instructionsNode;
}

// Helper functions to build the parse tree
Node buildLineNode(String line) {
  Node lineNode = Node('line');
  List<String> parts = line.split(' ');

  if (parts[0] == 'sqr') {
    lineNode.children.add(Node('sqr'));
    lineNode.children.add(buildXYNode(parts[1].split(',')[0]));
    lineNode.children.add(buildXYNode(parts[1].split(',')[1]));
  } else if (parts[0] == 'tri') {
    lineNode.children.add(Node('tri'));
    lineNode.children.add(buildXYNode(parts[1].split(',')[0]));
    lineNode.children.add(buildXYNode(parts[1].split(',')[1]));
    lineNode.children.add(buildXYNode(parts[1].split(',')[2]));
  } else {
    throw Exception('Invalid line: $line');
  }

  return lineNode;
}

// Helper functions to build the parse tree
Node buildXYNode(String xy) {
  Node xyNode = Node('xy');
  xyNode.children.add(Node(xy[0], [Node('x')]));
  xyNode.children.add(Node(xy[1], [Node('y')]));
  return xyNode;
}

void drawParseTree(Node node, {String prefix = '', bool isLast = true}) {
  print('$prefix${isLast ? '└── ' : '├── '}${node.value}');
  for (int i = 0; i < node.children.length; i++) {
    drawParseTree(
      node.children[i],
      prefix: '$prefix${isLast ? '    ' : '│   '}',
      isLast: i == node.children.length - 1,
    );
  }
}

// Main function
void main() {
  print('''
  **BNF Grammar:**

  <proc> → ON <body> OFF
  <body> → <instructions>
  <instructions> → <line> | <line> - <instructions>
  <line> → sqr <xy>,<xy> | tri <xy>,<xy>,<xy>
  <xy> → <x><y>
  <x> → a | b | c | d | e | f
  <y> → 1 | 2 | 3 | 4 | 5 | 6
  ''');

  while (true) {
    stdout.write('Enter a string (or "HALT" to quit): ');
    String? input = stdin.readLineSync();

    if (input == null || input == 'HALT') {
      break;
    }

    try {
      List<String> sententialForms = rightmostDerivation(input);
      print('Sentential forms:');
      for (String form in sententialForms) {
        print(form);
      }
      print('\nFinal generated sentence: $input');

      Node parseTree = buildParseTree(input);
      print('\nParse Tree:');
      drawParseTree(parseTree);

      stdout.write('Press Enter to continue: ');
      stdin.readLineSync();
    } catch (e) {
      print('Error: $e');
      stdout.write('Press Enter to continue: ');
      stdin.readLineSync();
    }
  }
}
