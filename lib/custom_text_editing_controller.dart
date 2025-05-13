import 'package:flutter/material.dart';
import 'package:mm_annonator/utils.dart';

class CustomTextEditingController extends TextEditingController {
  final Map<String, String> dictionary;
  final Set<String> newlyAddedWords = {};

  CustomTextEditingController({required this.dictionary});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    bool? withComposing,
  }) {
    final List<InlineSpan> children = [];
    String text = this.text;
    int currentIndex = 0;

    // Tokenize the text to identify dictionary and newly added words
    List<String> syllables = syllableSplit(text);
    List<String> tokens = maximumMatching(syllables, dictionary);

    for (String token in tokens) {
      int startIndex = text.indexOf(token, currentIndex);
      if (startIndex >= 0) {
        // Add unstyled text before the token
        if (startIndex > currentIndex) {
          children.add(
            TextSpan(
              text: text.substring(currentIndex, startIndex),
              style: style,
            ),
          );
        }

        // Apply style based on whether the token is in dictionary or newly added
        TextStyle tokenStyle = style ?? const TextStyle();
        if (dictionary.containsKey(token)) {
          tokenStyle = tokenStyle.copyWith(backgroundColor: Colors.yellow);
          children.add(TextSpan(text: ' ', style: tokenStyle));
        } else if (newlyAddedWords.contains(token)) {
          tokenStyle = tokenStyle.copyWith(backgroundColor: Colors.green);
          children.add(TextSpan(text: ' ', style: tokenStyle));
        }

        children.add(TextSpan(text: token, style: tokenStyle));

        if (dictionary.containsKey(token) || newlyAddedWords.contains(token)) {
          children.add(TextSpan(text: ' ', style: tokenStyle));
        }

        currentIndex = startIndex + token.length;
      }
    }

    // Add remaining text
    if (currentIndex < text.length) {
      children.add(TextSpan(text: text.substring(currentIndex), style: style));
    }

    return TextSpan(style: style, children: children);
  }

  void addNewWord(String word, String tag) {
    if (!dictionary.containsKey(word)) {
      newlyAddedWords.add(word);
      dictionary[word] = tag;
    }
  }
}
