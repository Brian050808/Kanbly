import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Controlador de edición enriquecida en vivo (estilo Xiaomi Notes / Word)
/// Aplica estilos visuales directamente dentro del TextFormField mientras el usuario escribe.
class FormattedTextEditingController extends TextEditingController {
  String _previousText = '';

  FormattedTextEditingController({super.text}) {
    _previousText = text;
  }

  @override
  set value(TextEditingValue newValue) {
    TextEditingValue finalValue = newValue;

    if (newValue.text != _previousText) {
      final sel = newValue.selection;
      if (sel.isCollapsed && sel.start > 0 && sel.start <= newValue.text.length) {
        final pos = sel.start;
        final currentText = newValue.text;

        // Verificar si se acaba de presionar Enter ('\n')
        if (currentText.length == _previousText.length + 1 && currentText[pos - 1] == '\n') {
          final textBefore = currentText.substring(0, pos - 1);
          final lastNewlineIndex = textBefore.lastIndexOf('\n');
          final prevLine = (lastNewlineIndex != -1)
              ? textBefore.substring(lastNewlineIndex + 1)
              : textBefore;

          final trimmedPrev = prevLine.trimLeft();

          // 1. CASILLA DE VERIFICACIÓN (- [ ] o - [x])
          if (trimmedPrev.startsWith('- [ ] ') || trimmedPrev.startsWith('- [x] ') || trimmedPrev.startsWith('- [X] ')) {
            final prefix = prevLine.startsWith('  ') ? '  - [ ] ' : '- [ ] ';
            final content = trimmedPrev.length > 6 ? trimmedPrev.substring(6).trim() : '';

            if (content.isEmpty) {
              // Si la línea previa estaba vacía (solo el checkbox), borrar la casilla previa y terminar lista
              final startPrevLine = (lastNewlineIndex != -1) ? lastNewlineIndex + 1 : 0;
              final newText = currentText.replaceRange(startPrevLine, pos, '\n');
              finalValue = TextEditingValue(
                text: newText,
                selection: TextSelection.collapsed(offset: startPrevLine + 1),
              );
            } else {
              // Continuar lista de casilla
              final newText = currentText.replaceRange(pos, pos, prefix);
              finalValue = TextEditingValue(
                text: newText,
                selection: TextSelection.collapsed(offset: pos + prefix.length),
              );
            }
          }
          // 2. LISTA DE VIÑETAS (- o *)
          else if (trimmedPrev.startsWith('- ') || trimmedPrev.startsWith('* ')) {
            final bulletChar = trimmedPrev[0];
            final prefix = prevLine.startsWith('  ') ? '  $bulletChar ' : '$bulletChar ';
            final content = trimmedPrev.length > 2 ? trimmedPrev.substring(2).trim() : '';

            if (content.isEmpty) {
              // Si la línea previa estaba vacía (solo la viñeta), borrarla y terminar la lista
              final startPrevLine = (lastNewlineIndex != -1) ? lastNewlineIndex + 1 : 0;
              final newText = currentText.replaceRange(startPrevLine, pos, '\n');
              finalValue = TextEditingValue(
                text: newText,
                selection: TextSelection.collapsed(offset: startPrevLine + 1),
              );
            } else {
              // Continuar lista con viñeta
              final newText = currentText.replaceRange(pos, pos, prefix);
              finalValue = TextEditingValue(
                text: newText,
                selection: TextSelection.collapsed(offset: pos + prefix.length),
              );
            }
          }
        }
      }
    }

    _previousText = finalValue.text;
    super.value = finalValue;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? const TextStyle();
    final textVal = text;

    if (textVal.isEmpty) {
      return TextSpan(style: baseStyle, text: '');
    }

    List<TextSpan> spans = [];
    final lines = textVal.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineEnding = (i < lines.length - 1) ? '\n' : '';

      if (line.startsWith('### ')) {
        // Encabezado en vivo estilo Word / Xiaomi Notes
        spans.add(TextSpan(
          text: '### ',
          style: baseStyle.copyWith(
            color: const Color(0xFF52ABEB).withOpacity(0.5),
            fontSize: (baseStyle.fontSize ?? 14) * 0.85,
            fontWeight: FontWeight.bold,
          ),
        ));
        _parseInlineFormatting(
          line.substring(4) + lineEnding,
          baseStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: (baseStyle.fontSize ?? 14) + 3,
            color: const Color(0xFF52ABEB),
          ),
          spans,
        );
      } else if (line.startsWith('- [x] ') || line.startsWith('- [X] ')) {
        // Casilla marcada en vivo
        spans.add(TextSpan(
          text: '[✓] ',
          style: baseStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF63D0A1),
          ),
        ));
        _parseInlineFormatting(
          line.substring(6) + lineEnding,
          baseStyle.copyWith(
            color: const Color(0xFF94A3B8),
            decoration: TextDecoration.lineThrough,
          ),
          spans,
        );
      } else if (line.startsWith('- [ ] ')) {
        // Casilla pendiente en vivo
        spans.add(TextSpan(
          text: '[ ] ',
          style: baseStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF52ABEB),
          ),
        ));
        _parseInlineFormatting(line.substring(6) + lineEnding, baseStyle, spans);
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        // Viñeta en vivo
        spans.add(TextSpan(
          text: '• ',
          style: baseStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF52ABEB),
          ),
        ));
        _parseInlineFormatting(line.substring(2) + lineEnding, baseStyle, spans);
      } else {
        // Línea regular con formato en vivo
        _parseInlineFormatting(line + lineEnding, baseStyle, spans);
      }
    }

    return TextSpan(style: baseStyle, children: spans);
  }

  void _parseInlineFormatting(
    String lineText,
    TextStyle baseStyle,
    List<TextSpan> spans,
  ) {
    // Regex para encontrar **negrita** o *cursiva*
    final regExp = RegExp(r'(\*\*[^*]+\*\*|\*[^*]+\*)');
    int lastIndex = 0;

    // Color tenue para atenuar los delimitadores de formato (** o *)
    final Color delimiterColor = Colors.grey.withOpacity(0.38);

    for (final match in regExp.allMatches(lineText)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: lineText.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }

      final matchedText = match.group(0)!;
      if (matchedText.startsWith('**') && matchedText.endsWith('**') && matchedText.length >= 4) {
        // Negrita en vivo
        final innerText = matchedText.substring(2, matchedText.length - 2);
        spans.add(TextSpan(
          text: '**',
          style: baseStyle.copyWith(
            color: delimiterColor,
            fontWeight: FontWeight.normal,
          ),
        ));
        spans.add(TextSpan(
          text: innerText,
          style: baseStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ));
        spans.add(TextSpan(
          text: '**',
          style: baseStyle.copyWith(
            color: delimiterColor,
            fontWeight: FontWeight.normal,
          ),
        ));
      } else if (matchedText.startsWith('*') && matchedText.endsWith('*') && matchedText.length >= 2) {
        // Cursiva en vivo
        final innerText = matchedText.substring(1, matchedText.length - 1);
        spans.add(TextSpan(
          text: '*',
          style: baseStyle.copyWith(
            color: delimiterColor,
            fontStyle: FontStyle.normal,
          ),
        ));
        spans.add(TextSpan(
          text: innerText,
          style: baseStyle.copyWith(
            fontStyle: FontStyle.italic,
            color: const Color(0xFF1E293B),
          ),
        ));
        spans.add(TextSpan(
          text: '*',
          style: baseStyle.copyWith(
            color: delimiterColor,
            fontStyle: FontStyle.normal,
          ),
        ));
      } else {
        spans.add(TextSpan(text: matchedText, style: baseStyle));
      }

      lastIndex = match.end;
    }

    if (lastIndex < lineText.length) {
      spans.add(TextSpan(
        text: lineText.substring(lastIndex),
        style: baseStyle,
      ));
    }
  }
}

/// Barra de herramientas intuitiva e interactiva para aplicar formato con 1 toque (estilo Xiaomi Notes / Word)
class BarraHerramientasFormato extends StatefulWidget {
  final TextEditingController controller;

  const BarraHerramientasFormato({
    super.key,
    required this.controller,
  });

  @override
  State<BarraHerramientasFormato> createState() => _BarraHerramientasFormatoState();
}

class _BarraHerramientasFormatoState extends State<BarraHerramientasFormato> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant BarraHerramientasFormato oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  bool get _isBoldActive {
    final text = widget.controller.text;
    final sel = widget.controller.selection;
    if (sel.start < 0) return false;

    if (sel.start != sel.end) {
      final selectedText = text.substring(sel.start, sel.end);
      return selectedText.startsWith('**') && selectedText.endsWith('**');
    }

    final pos = sel.start;
    final before = text.substring(0, pos);
    final after = text.substring(pos);

    final lastOpening = before.lastIndexOf('**');
    if (lastOpening != -1) {
      final closing = after.indexOf('**');
      if (closing != -1) return true;
    }
    return false;
  }

  bool get _isItalicActive {
    final text = widget.controller.text;
    final sel = widget.controller.selection;
    if (sel.start < 0) return false;

    if (sel.start != sel.end) {
      final selectedText = text.substring(sel.start, sel.end);
      return selectedText.startsWith('*') && selectedText.endsWith('*') && !selectedText.startsWith('**');
    }

    final pos = sel.start;
    final before = text.substring(0, pos);
    final after = text.substring(pos);

    final lastOpening = before.lastIndexOf('*');
    if (lastOpening != -1 && (lastOpening == 0 || before[lastOpening - 1] != '*')) {
      final closing = after.indexOf('*');
      if (closing != -1 && (closing == after.length - 1 || after[closing + 1] != '*')) return true;
    }
    return false;
  }

  String get _currentLinePrefix {
    final text = widget.controller.text;
    final sel = widget.controller.selection;
    int pos = sel.start >= 0 ? sel.start : text.length;

    final lastNewline = text.lastIndexOf('\n', pos > 0 ? pos - 1 : 0);
    final lineStart = (lastNewline != -1) ? lastNewline + 1 : 0;
    final nextNewline = text.indexOf('\n', pos);
    final lineEnd = (nextNewline != -1) ? nextNewline : text.length;

    if (lineStart > lineEnd) return '';
    final line = text.substring(lineStart, lineEnd).trimLeft();

    if (line.startsWith('### ')) return '### ';
    if (line.startsWith('- [ ] ') || line.startsWith('- [x] ') || line.startsWith('- [X] ')) return '- [ ] ';
    if (line.startsWith('- ') || line.startsWith('* ')) return '- ';

    return '';
  }

  void _toggleBold() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    int start = selection.start;
    int end = selection.end;

    if (start < 0 || end < 0 || start > text.length || end > text.length) {
      start = text.length;
      end = text.length;
    }

    if (start != end) {
      final seleccionado = text.substring(start, end);
      if (seleccionado.startsWith('**') && seleccionado.endsWith('**') && seleccionado.length >= 4) {
        // Quitar negrita
        final sinNegrita = seleccionado.substring(2, seleccionado.length - 2);
        final nuevoTexto = text.replaceRange(start, end, sinNegrita);
        widget.controller.text = nuevoTexto;
        widget.controller.selection = TextSelection(baseOffset: start, extentOffset: start + sinNegrita.length);
      } else {
        // Aplicar negrita
        final nuevoTexto = text.replaceRange(start, end, '**$seleccionado**');
        widget.controller.text = nuevoTexto;
        widget.controller.selection = TextSelection(baseOffset: start + 2, extentOffset: end + 2);
      }
    } else {
      // Sin selección
      if (_isBoldActive) {
        // Si el cursor está dentro de **texto|**, avanzar después de los dos asteriscos de cierre
        final after = text.substring(start);
        final nextClosing = after.indexOf('**');
        if (nextClosing != -1) {
          widget.controller.selection = TextSelection.collapsed(offset: start + nextClosing + 2);
          return;
        }
      }
      // Insertar **** y colocar cursor en medio (**|**) para escribir inmediatamente en negrita
      final nuevoTexto = text.replaceRange(start, end, '****');
      widget.controller.text = nuevoTexto;
      widget.controller.selection = TextSelection.collapsed(offset: start + 2);
    }
  }

  void _toggleItalic() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    int start = selection.start;
    int end = selection.end;

    if (start < 0 || end < 0 || start > text.length || end > text.length) {
      start = text.length;
      end = text.length;
    }

    if (start != end) {
      final seleccionado = text.substring(start, end);
      if (seleccionado.startsWith('*') && seleccionado.endsWith('*') && !seleccionado.startsWith('**') && seleccionado.length >= 2) {
        // Quitar cursiva
        final sinCursiva = seleccionado.substring(1, seleccionado.length - 1);
        final nuevoTexto = text.replaceRange(start, end, sinCursiva);
        widget.controller.text = nuevoTexto;
        widget.controller.selection = TextSelection(baseOffset: start, extentOffset: start + sinCursiva.length);
      } else {
        // Aplicar cursiva
        final nuevoTexto = text.replaceRange(start, end, '*$seleccionado*');
        widget.controller.text = nuevoTexto;
        widget.controller.selection = TextSelection(baseOffset: start + 1, extentOffset: end + 1);
      }
    } else {
      // Sin selección
      if (_isItalicActive) {
        final after = text.substring(start);
        final nextClosing = after.indexOf('*');
        if (nextClosing != -1) {
          widget.controller.selection = TextSelection.collapsed(offset: start + nextClosing + 1);
          return;
        }
      }
      final nuevoTexto = text.replaceRange(start, end, '**');
      widget.controller.text = nuevoTexto;
      widget.controller.selection = TextSelection.collapsed(offset: start + 1);
    }
  }

  void _toggleLinePrefix(String prefijo) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    int pos = selection.start >= 0 ? selection.start : text.length;

    final lastNewline = text.lastIndexOf('\n', pos > 0 ? pos - 1 : 0);
    final lineStart = (lastNewline != -1) ? lastNewline + 1 : 0;

    final currentPrefix = _currentLinePrefix;

    if (currentPrefix.isNotEmpty) {
      // Si la línea ya tiene un prefijo de formato
      final lineText = text.substring(lineStart);
      int prefixLength = 0;
      if (lineText.startsWith('### ')) prefixLength = 4;
      else if (lineText.startsWith('- [ ] ') || lineText.startsWith('- [x] ') || lineText.startsWith('- [X] ')) prefixLength = 6;
      else if (lineText.startsWith('- ') || lineText.startsWith('* ')) prefixLength = 2;

      // Si es el mismo prefijo, quitarlo
      if (currentPrefix == prefijo) {
        final nuevoTexto = text.replaceRange(lineStart, lineStart + prefixLength, '');
        widget.controller.text = nuevoTexto;
        widget.controller.selection = TextSelection.collapsed(offset: (pos - prefixLength).clamp(lineStart, nuevoTexto.length));
        return;
      } else {
        // Reemplazar por el nuevo prefijo
        final nuevoTexto = text.replaceRange(lineStart, lineStart + prefixLength, prefijo);
        widget.controller.text = nuevoTexto;
        widget.controller.selection = TextSelection.collapsed(offset: (pos - prefixLength + prefijo.length).clamp(lineStart, nuevoTexto.length));
        return;
      }
    }

    // Si la línea no tiene prefijo, agregarlo al inicio de la línea
    final nuevoTexto = text.replaceRange(lineStart, lineStart, prefijo);
    widget.controller.text = nuevoTexto;
    widget.controller.selection = TextSelection.collapsed(offset: pos + prefijo.length);
  }

  @override
  Widget build(BuildContext context) {
    const Color azulCielo = Color(0xFF52ABEB);
    final currentPrefix = _currentLinePrefix;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text(
              ' Formato: ',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            // NEGRITA
            _botonFormato(
              icon: Icons.format_bold_rounded,
              tooltip: 'Negrita (**texto**)',
              activo: _isBoldActive,
              onTap: _toggleBold,
            ),
            // CURSIVA
            _botonFormato(
              icon: Icons.format_italic_rounded,
              tooltip: 'Cursiva (*texto*)',
              activo: _isItalicActive,
              onTap: _toggleItalic,
            ),
            const SizedBox(width: 4),
            Container(height: 16, width: 1, color: Colors.grey.shade400),
            const SizedBox(width: 4),
            // VIÑETA
            _botonFormato(
              icon: Icons.format_list_bulleted_rounded,
              tooltip: 'Lista con Viñeta (- elemento)',
              activo: currentPrefix == '- ',
              onTap: () => _toggleLinePrefix('- '),
            ),
            // CHECKLIST / CASILLA DE VERIFICACIÓN
            _botonFormato(
              icon: Icons.check_box_outlined,
              tooltip: 'Lista de Tareas (- [ ] pendiente)',
              activo: currentPrefix == '- [ ] ',
              onTap: () => _toggleLinePrefix('- [ ] '),
            ),
            // ENCABEZADO
            _botonFormato(
              icon: Icons.title_rounded,
              tooltip: 'Título / Encabezado (### Título)',
              activo: currentPrefix == '### ',
              onTap: () => _toggleLinePrefix('### '),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botonFormato({
    required IconData icon,
    required String tooltip,
    required bool activo,
    required VoidCallback onTap,
  }) {
    const Color azulCielo = Color(0xFF52ABEB);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: activo ? azulCielo.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: activo ? Border.all(color: azulCielo, width: 1.2) : null,
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: activo ? azulCielo : const Color(0xFF1E293B)),
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: const EdgeInsets.all(4),
        onPressed: onTap,
      ),
    );
  }
}

/// Renderiza texto plano enriquecido con listas de viñetas, checklists, encabezados y negritas
class VisorTextoFormateado extends StatelessWidget {
  final String texto;
  final TextStyle? style;

  const VisorTextoFormateado({
    super.key,
    required this.texto,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (texto.trim().isEmpty) {
      return Text(
        'Sin información detallada.',
        style: style ?? GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
      );
    }

    final lineas = texto.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: lineas.map((linea) => _renderizarLinea(context, linea)).toList(),
    );
  }

  Widget _renderizarLinea(BuildContext context, String linea) {
    const Color textoPrincipal = Color(0xFF1E293B);
    const Color verdeTurquesa = Color(0xFF63D0A1);
    const Color azulCielo = Color(0xFF52ABEB);

    final trimmed = linea.trimLeft();

    // 1. ENCABEZADOS (### Título)
    if (trimmed.startsWith('### ')) {
      final contenido = trimmed.substring(4);
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(
          contenido,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: azulCielo,
          ),
        ),
      );
    }

    // 2. CHECKLIST MARCADOR (- [x] o - [X])
    if (trimmed.startsWith('- [x] ') || trimmed.startsWith('- [X] ') || trimmed.startsWith('* [x] ')) {
      final contenido = trimmed.substring(6);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.check_box_rounded, size: 18, color: verdeTurquesa),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                contenido,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 3. CHECKLIST PENDIENTE (- [ ])
    if (trimmed.startsWith('- [ ] ') || trimmed.startsWith('* [ ] ')) {
      final contenido = trimmed.substring(6);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.check_box_outline_blank_rounded, size: 18, color: Colors.grey.shade500),
            const SizedBox(width: 8),
            Expanded(
              child: _renderizarTextSpans(contenido, textoPrincipal),
            ),
          ],
        ),
      );
    }

    // 4. LISTA CON VIÑETAS (- Elemento o * Elemento)
    if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
      final contenido = trimmed.substring(2);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 6, right: 8),
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: azulCielo,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: _renderizarTextSpans(contenido, textoPrincipal),
            ),
          ],
        ),
      );
    }

    // 5. PARÁGRAFO REGULAR CON SOPORTE PARA **NEGRITA** Y *CURSIVA*
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: _renderizarTextSpans(linea, textoPrincipal),
    );
  }

  /// Procesa texto buscando marcadores de **negrita** o *cursiva*
  Widget _renderizarTextSpans(String textoLinea, Color colorBase) {
    List<TextSpan> spans = [];
    final regExp = RegExp(r'(\*\*[^*]+\*\*|\*[^*]+\*)');

    int lastIndex = 0;
    for (final match in regExp.allMatches(textoLinea)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: textoLinea.substring(lastIndex, match.start),
          style: TextStyle(color: colorBase),
        ));
      }

      final matchedText = match.group(0)!;
      if (matchedText.startsWith('**') && matchedText.endsWith('**')) {
        spans.add(TextSpan(
          text: matchedText.substring(2, matchedText.length - 2),
          style: TextStyle(fontWeight: FontWeight.bold, color: colorBase),
        ));
      } else if (matchedText.startsWith('*') && matchedText.endsWith('*')) {
        spans.add(TextSpan(
          text: matchedText.substring(1, matchedText.length - 1),
          style: TextStyle(fontStyle: FontStyle.italic, color: colorBase),
        ));
      }

      lastIndex = match.end;
    }

    if (lastIndex < textoLinea.length) {
      spans.add(TextSpan(
        text: textoLinea.substring(lastIndex),
        style: TextStyle(color: colorBase),
      ));
    }

    return SelectableText.rich(
      TextSpan(
        children: spans.isNotEmpty
            ? spans
            : [TextSpan(text: textoLinea, style: TextStyle(color: colorBase))],
      ),
      style: GoogleFonts.inter(fontSize: 13, height: 1.4),
    );
  }
}
