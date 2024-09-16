import 'dart:convert';
import 'dart:io';

//HELPER functions
Future<void> myPrint(String output) async {
  stdout.write(output);
}

//REGEX
final halt = RegExp(r"^HALT$");

final r_off = RegExp(r"^OFF$");
final r_on = RegExp(r"^ON$");
final r_sqr = RegExp(r"^sqr$");
final r_tri = RegExp(r"^tri$");
final r_xyChain = RegExp(r"^(([a-f][1-6]),){1,2}([a-f][1-6])$");
final r_sqrXY = RegExp(r"^(([a-f][1-6]),)([a-f][1-6])$");
final r_triXY = RegExp(r"^(([a-f][1-6]),){2}([a-f][1-6])$");
final r_delim = RegExp(r"^-$");

//MAIN
void main() {
  //Core Programming Loop
  while (true) {
    //Printing the grammar
    myPrint("\n\n");
    myPrint("<proc> ->  ON <body> OFF\n");
    myPrint("<body> ->  <line>\n");
    myPrint("          |<line> - <instructions>\n");
    myPrint("<line> -> sqr <xy>,<xy>\n");
    myPrint("          | <xy>,<xy>,<xy>\n");
    myPrint("<xy>   -> <x><y>\n");
    myPrint("<x>    -> a | b | c | d | e | f\n");
    myPrint("<y>    -> 1 | 2 | 3 | 4 | 5 | 6\n\n");

    //Prompting the user
    stdout.write("Enter your sentence: ");
    var userInput = stdin.readLineSync(encoding: utf8);

    //Checking the input from the user
    if (userInput != null && halt.hasMatch(userInput)) {
      break;
    } else if (userInput != null) {
      LanguageRecognizer(userInput);
    }
  }
}

//Language Recognizer
void LanguageRecognizer(String input) {
  //removing all the trailing white spaces
  input = input.trim();

  //tokenizing the string
  List<String> tokenList = input.split(RegExp(r"\s+"));
  List<String> checkedList = [];

  //checking if OFF is correct
  if (r_off.hasMatch(tokenList.last)) {
    //moving the valid token
    checkedList.insert(0, tokenList.removeLast());
  } else {
    //there is an error
    ReportError(checkedList, tokenList, "OFF");
    return;
  }

  //checking if the next token is a sqr line or tri line
  while (true) {
    if (r_xyChain.hasMatch(tokenList.last)) {
      //moving the valid token
      checkedList.insert(0, tokenList.removeLast());

      //checking if the rest of the line is correct
      if (r_sqr.hasMatch(tokenList.last) || r_tri.hasMatch(tokenList.last)) {
        //moving the valid token
        checkedList.insert(0, tokenList.removeLast());

        if (tokenList.length == 1) {
          //stopping the loop to validate the expected ON token
          break;
        } else if (r_delim.hasMatch(tokenList.last)) {
          //moving the valid token
          checkedList.insert(0, tokenList.removeLast());

          //checking the expected next line
          continue;
        } else {
          //there is an error
          ReportError(checkedList, tokenList, "- or ON");
          return;
        }
      } else {
        //there is an error with the sqr or tri
        if (r_triXY.hasMatch(checkedList[0])) {
          ReportError(checkedList, tokenList, "tri");
        } else if (r_sqrXY.hasMatch(checkedList[0])) {
          ReportError(checkedList, tokenList, "sqr");
        }
        return;
      }
    } else {
      //there is an error in the xy chain

      //removing the error token
      String wrongToken = tokenList.removeLast();

      //decomposing the token
      List<String> itemizedToken = wrongToken.split("");
      List<String> iCheckedToken = [];

      //looping through the list from back to front
      while (true) {
        //First check for the Y
        if (RegExp(r"[1-6]").hasMatch(itemizedToken.last)) {
          //move the token
          iCheckedToken.insert(0, itemizedToken.removeLast());

          //check for the X
          if (RegExp(r"[a-f]").hasMatch(itemizedToken.last)) {
            //move the token
            iCheckedToken.insert(0, itemizedToken.removeLast());

            //check if we have a complete line
            if (iCheckedToken.length == 2 || iCheckedToken.length == 5) {
              if (RegExp(r",").hasMatch(itemizedToken.last)) {
                //move the token
                iCheckedToken.insert(0, itemizedToken.removeLast());
                continue;
              } else {
                //incorrect delim
                ReportXYChainError(
                    checkedList, tokenList, ",", itemizedToken, iCheckedToken);
                return;
              }
            } else {
              //addition token in the xy chain

              ReportXYChainError(checkedList, tokenList, "whitespace",
                  itemizedToken, iCheckedToken);
              return;
            }
          } else {
            //incorrect x
            ReportXYChainError(checkedList, tokenList, "a | b | c | d | e | f",
                itemizedToken, iCheckedToken);
            return;
          }
        } else {
          //incorrect y
          ReportXYChainError(checkedList, tokenList, "1 | 2 | 3 | 4 | 5 | 6",
              itemizedToken, iCheckedToken);
          return;
        }
      }
    }
  }

  //checking if the ON is correct
  if (r_on.hasMatch(tokenList.last)) {
    //moving the valid token
    checkedList.insert(0, tokenList.removeLast());
  } else {
    //there is an error
    ReportError(checkedList, tokenList, "ON");
    return;
  }

  myPrint("\n\nValid Sentence\n\n");
}

void ReportError(List<String> checked, List<String> input, String expected) {
  //grabbing the error token
  String errorToken = input.removeLast();

  String whiteSpace = "";

  //padding the whitespace before the error marker
  for (int i = 0; i < input.length; i++) {
    for (int j = 0; j < input[i].length; j++) {
      whiteSpace += " ";
    }
    whiteSpace += " ";
  }

  //creating the error marker
  for (int i = 0; i < errorToken.length; i++) {
    whiteSpace += "^";
  }

  //reporting the error
  myPrint("\n");
  for (int i = 0; i < input.length; i++) {
    myPrint("${input[i]} ");
  }
  myPrint("${errorToken} ");
  for (int i = 0; i < checked.length; i++) {
    myPrint("${checked[i]} ");
  }
  myPrint("\n${whiteSpace}\n");
  myPrint(
      "Syntax Error: expected \"${expected}\"; but got \"${errorToken}\" instead\n");
}

void ReportXYChainError(List<String> checked, List<String> input,
    String expected, List<String> onTokenInput, List<String> onTokenChecked) {
  //reconstruct the errorToken and creating a error marker for the said errorSubToken
  String errorSubToken = onTokenInput.removeLast();

  String reconstructedToken = "";
  String subTokenErrorMarker = "";

  for (int i = 0; i < onTokenInput.length; i++) {
    reconstructedToken += onTokenInput[i];
    subTokenErrorMarker += " ";
  }

  reconstructedToken += errorSubToken;
  subTokenErrorMarker += "^";

  for (int i = 0; i < onTokenChecked.length; i++) {
    reconstructedToken += onTokenChecked[i];
    subTokenErrorMarker += " ";
  }

  //padding the whitespace before the error marker
  String whiteSpace = "";

  for (int i = 0; i < input.length; i++) {
    for (int j = 0; j < input[i].length; j++) {
      whiteSpace += " ";
    }
    whiteSpace += " ";
  }

  //reporting the error
  myPrint("\n");
  for (int i = 0; i < input.length; i++) {
    myPrint("${input[i]} ");
  }
  myPrint("${reconstructedToken} ");
  for (int i = 0; i < checked.length; i++) {
    myPrint("${checked[i]} ");
  }
  myPrint("\n${whiteSpace}${subTokenErrorMarker}\n");
  myPrint(
      "Syntax Error: expected \"${expected}\"; but got \"${errorSubToken}\" instead\n");
}
