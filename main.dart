import 'dart:io';

void main() {
  while (true) {
    stdout.write('Enter your name? ');
    late String? input = stdin.readLineSync();

    /// Read user input
    if (input == "HALT" || input == "halt") {
      print("Program EXITED");
      break;
    }

    /// Process the valid input
    print('Hello, $input! \n\n');

    /// Example of handling valid input
  }
}
