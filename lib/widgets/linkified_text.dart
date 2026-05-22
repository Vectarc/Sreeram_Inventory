import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkifiedText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const LinkifiedText({super.key, required this.text, required this.style});
  @override
  State<LinkifiedText> createState() => _LinkifiedTextState();
}

class _LinkifiedTextState extends State<LinkifiedText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  void _clearRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    String formattedUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      formattedUrl = 'https://$url';
    }

    final Uri uri = Uri.parse(formattedUrl);
    final bool isYouTube =
        formattedUrl.toLowerCase().contains('youtube.com') ||
        formattedUrl.toLowerCase().contains('youtu.be');

    try {
      if (isYouTube) {
        // Try launching in native YouTube app
        bool launchedInApp = false;
        try {
          launchedInApp = await launchUrl(
            uri,
            mode: LaunchMode.externalNonBrowserApplication,
          );
        } catch (_) {
          // Ignore and let it fall back to browser
        }
        if (!launchedInApp) {
          // Fallback to external application (browser)
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        // Normal web URLs
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch link: $url\nError: $e')),
        );
      }
    }
  }

  List<TextSpan> _parseText(String text) {
    _clearRecognizers();
    final List<TextSpan> spans = [];

    // Pattern to match common web links and specifically youtube URLs without scheme
    final RegExp urlRegExp = RegExp(
      r'(https?:\/\/[^\s]+|www\.[^\s]+|youtube\.com\/[^\s]+|youtu\.be\/[^\s]+)',
      caseSensitive: false,
    );

    final Iterable<RegExpMatch> matches = urlRegExp.allMatches(text);
    int lastMatchEnd = 0;

    for (final RegExpMatch match in matches) {
      // Add text before the URL
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: widget.style,
          ),
        );
      }

      final String url = match.group(0)!;
      final TapGestureRecognizer recognizer = TapGestureRecognizer()
        ..onTap = () => _launchURL(context, url);
      _recognizers.add(recognizer);

      // Add clickable URL
      spans.add(
        TextSpan(
          text: url,
          style: widget.style.copyWith(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
          recognizer: recognizer,
        ),
      );

      lastMatchEnd = match.end;
    }

    // Add remaining text after the last URL
    if (lastMatchEnd < text.length) {
      spans.add(
        TextSpan(text: text.substring(lastMatchEnd), style: widget.style),
      );
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.text.isEmpty) {
      return Text('', style: widget.style);
    }

    return RichText(text: TextSpan(children: _parseText(widget.text)));
  }
}
