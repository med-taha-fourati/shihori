String cleanFilename(String input) {
  return input.replaceAll(RegExp(r'[-<>:/\\|?*]'), '');
}