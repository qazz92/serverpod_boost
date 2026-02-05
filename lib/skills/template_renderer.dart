/// Template renderer for skills
///
/// Renders Mustache templates with project context.
library serverpod_boost.skills.template_renderer;

import 'package:mustache_template/mustache_template.dart';

import '../project_context.dart';

/// Template renderer for skill templates
class TemplateRenderer {

  const TemplateRenderer({
    required this.context,
    this.customVars = const {},
  });
  /// Project context for rendering
  final ProjectContext context;

  /// Additional custom variables
  final Map<String, dynamic> customVars;

  /// Render a template with context
  String render(String template, [Map<String, dynamic>? extraVars]) {
    final mergedVars = {
      ...context.toTemplateVars(),
      ...customVars,
      ...?extraVars,
    };

    try {
      final compiled = Template(template, htmlEscapeValues: false);
      return compiled.renderString(mergedVars);
    } catch (e) {
      // Fallback: return template with error note
      return '$template\n\n[Render Error: $e]';
    }
  }

  /// Create a new renderer with additional custom variables
  TemplateRenderer withVars(Map<String, dynamic> vars) {
    return TemplateRenderer(
      context: context,
      customVars: {...customVars, ...vars},
    );
  }

  /// Get template variables as a map
  Map<String, dynamic> get templateVars => {
        ...context.toTemplateVars(),
        ...customVars,
      };
}
