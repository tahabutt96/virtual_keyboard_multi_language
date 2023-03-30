part of virtual_keyboard_multi_language;

/// The default keyboard height. Can we overriden by passing
///  `height` argument to `VirtualKeyboard` widget.
const double _virtualKeyboardDefaultHeight = 300;

const int _virtualKeyboardBackspaceEventPerioud = 250;

/// Virtual Keyboard widget.
class VirtualKeyboard extends StatefulWidget {
  /// Keyboard Type: Should be inited in creation time.
  final VirtualKeyboardType type;

  /// The text controller
  final TextEditingController? textController;

  /// Virtual keyboard height. Default is 300
  final double height;

  /// Color for key texts and icons.
  final Color textColor;

  /// Font size for keyboard keys.
  final double fontSize;

  /// the custom layout for multi or single language
  final VirtualKeyboardLayoutKeys? customLayoutKeys;

  /// used for multi-languages with default layouts, the default is English only
  /// will be ignored if customLayoutKeys is not null
  final List<VirtualKeyboardDefaultLayouts> defaultLayouts;

  /// The builder function will be called for each Key object.
  final Widget Function(BuildContext context, VirtualKeyboardKey key)? builder;

  /// Set to true if you want only to show Caps letters.
  bool alwaysCaps, isShiftEnabled;

  final Function(VirtualKeyboardKey key)? onKeyPress;

  VirtualKeyboard(
      {Key? key,
      required this.type,
      required this.defaultLayouts,
      this.textController,
      this.builder,
      this.height = _virtualKeyboardDefaultHeight,
      this.textColor = Colors.black,
      this.fontSize = 14,
      this.customLayoutKeys,
      this.onKeyPress,
      this.isShiftEnabled = false,
      this.alwaysCaps = false})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VirtualKeyboardState();
  }
}

/// Holds the state for Virtual Keyboard class.
class _VirtualKeyboardState extends State<VirtualKeyboard> {
  VirtualKeyboardType? type;
  // The builder function will be called for each Key object.
  Widget Function(BuildContext context, VirtualKeyboardKey key)? builder;
  late double height;
  late TextEditingController textController;
  late Color textColor;
  late double fontSize;
  late bool alwaysCaps;
  // Text Style for keys.
  late TextStyle textStyle;
  late Function(VirtualKeyboardKey)? onKeyPress;
  late VirtualKeyboardLayoutKeys? customLayoutKeys;

  // True if shift is enabled.
  // bool isShiftEnabled = false;

  @override
  void didUpdateWidget(VirtualKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      type = widget.type;
      height = widget.height;
      textColor = widget.textColor;
      fontSize = widget.fontSize;
      alwaysCaps = widget.alwaysCaps;
      onKeyPress = widget.onKeyPress;
      customLayoutKeys = widget.customLayoutKeys ?? customLayoutKeys;

      // Init the Text Style for keys.
      textStyle = TextStyle(
        fontSize: fontSize,
        color: textColor,
      );
    });
  }

  @override
  void initState() {
    super.initState();

    textController = widget.textController ?? TextEditingController();
    type = widget.type;
    height = widget.height;
    textColor = widget.textColor;
    fontSize = widget.fontSize;
    alwaysCaps = widget.alwaysCaps;
    onKeyPress = widget.onKeyPress;
    customLayoutKeys = widget.customLayoutKeys ??
        VirtualKeyboardDefaultLayoutKeys(widget.defaultLayouts);

    // Init the Text Style for keys.
    textStyle = TextStyle(
      fontSize: fontSize,
      color: textColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return type == VirtualKeyboardType.Numeric ? _numeric() : _alphanumeric();
  }

  Widget _alphanumeric() {
    return Container(
      height: height,
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _rows(),
      ),
    );
  }

  Widget _numeric() {
    return Container(
      height: height,
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _rows(),
      ),
    );
  }

  /// Returns the rows for keyboard.
  List<Widget> _rows() {
    // Get the keyboard Rows
    List<List<VirtualKeyboardKey>> keyboardRows =
        type == VirtualKeyboardType.Numeric
            ? _getKeyboardRowsNumeric()
            : _getKeyboardRows(customLayoutKeys!);

    // Generate keyboard row.
    List<Widget> rows = List.generate(keyboardRows.length, (int rowNum) {
      return Material(
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          // Generate keboard keys
          children: List.generate(
            keyboardRows[rowNum].length,
            (int keyNum) {
              // Get the VirtualKeyboardKey object.
              VirtualKeyboardKey virtualKeyboardKey =
                  keyboardRows[rowNum][keyNum];

              Widget keyWidget;

              // Check if builder is specified.
              // Call builder function if specified or use default
              //  Key widgets if not.
              if (builder == null) {
                // Check the key type.
                switch (virtualKeyboardKey.keyType) {
                  case VirtualKeyboardKeyType.String:
                    // Draw String key.
                    keyWidget = _keyboardDefaultKey(virtualKeyboardKey);
                    break;
                  case VirtualKeyboardKeyType.Action:
                    // Draw action key.
                    keyWidget = _keyboardDefaultActionKey(virtualKeyboardKey);
                    break;
                }
              } else {
                // Call the builder function, so the user can specify custom UI for keys.
                keyWidget = builder!(context, virtualKeyboardKey);

                throw 'builder function must return Widget';
              }

              return keyWidget;
            },
          ),
        ),
      );
    });

    return rows;
  }

  // True if long press is enabled.
  late bool longPress;

  /// Creates default UI element for keyboard Key.
  Widget _keyboardDefaultKey(VirtualKeyboardKey key) {
    return Expanded(
        child: InkWell(
      onTap: () {
        if (onKeyPress != null) {
          onKeyPress!(key);
        } else {
          _onKeyPress(key);
        }
      },
      child: Container(
        height: height / customLayoutKeys!.activeLayout.length,
        child: Center(
            child: Text(
          alwaysCaps
              ? key.capsText!
              : (widget.isShiftEnabled ? key.capsText! : key.text!),
          style: textStyle,
        )),
      ),
    ));
  }

  void _onKeyPress(VirtualKeyboardKey key) {
    if (key.keyType == VirtualKeyboardKeyType.String) {
      // Insert text at selected position, replacing selected characters, fix selection position to end of edit
      final text = textController.text;
      final selection = textController.selection;
      final newText = text.replaceRange(selection.start, selection.end,
          (widget.isShiftEnabled ? key.capsText! : key.text!));
      textController.value = TextEditingValue(
        text: newText,
        selection:
            TextSelection.collapsed(offset: selection.start + key.text!.length),
      );
    } else if (key.keyType == VirtualKeyboardKeyType.Action) {
      switch (key.action) {
        case VirtualKeyboardKeyAction.Backspace:
          if (textController.text.length == 0) return;
          // Remove selected character(s), fix selection position to end of edit
          final text = textController.text;
          final selection = textController.selection;
          String newText = "";
          int offset = 0;
          if (selection.baseOffset > 0 && selection.start != selection.end) {
            newText = text.replaceRange(selection.start, selection.end, "");
            offset = selection.start;
          } else if (selection.baseOffset > 0) {
            newText = text.substring(0, selection.baseOffset - 1) +
                text.substring(selection.baseOffset, text.length);
            offset = selection.baseOffset - 1;
          }
          textController.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: offset),
          );
          break;
        case VirtualKeyboardKeyAction.Return:
          // Insert newline at selected position, replacing selected characters, fix selection position to end of edit
          final text = textController.text;
          final selection = textController.selection;
          final newText =
              text.replaceRange(selection.start, selection.end, "\n");
          textController.value = TextEditingValue(
            text: newText,
            selection:
                TextSelection.collapsed(offset: selection.start + "\n".length),
          );
          break;
        case VirtualKeyboardKeyAction.Space:
          // Insert space at selected position, replacing selected characters, fix selection position to end of edit
          final text = textController.text;
          final selection = textController.selection;
          final newText =
              text.replaceRange(selection.start, selection.end, key.text!);
          textController.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(
                offset: selection.start + key.text!.length),
          );
          break;
        case VirtualKeyboardKeyAction.Shift:
          break;
        default:
      }
    }
  }

  /// Creates default UI element for keyboard Action Key.
  Widget _keyboardDefaultActionKey(VirtualKeyboardKey key) {
    // Holds the action key widget.
    Widget actionKey;

    // Switch the action type to build action Key widget.
    switch (key.action!) {
      case VirtualKeyboardKeyAction.Backspace:
        actionKey = GestureDetector(
            onLongPress: () {
              longPress = true;
              // Start sending backspace key events while longPress is true
              Timer.periodic(
                  Duration(milliseconds: _virtualKeyboardBackspaceEventPerioud),
                  (timer) {
                if (longPress) {
                  if (onKeyPress != null) {
                    onKeyPress!(key);
                  } else {
                    _onKeyPress(key);
                  }
                } else {
                  // Cancel timer.
                  timer.cancel();
                }
              });
            },
            onLongPressUp: () {
              // Cancel event loop
              longPress = false;
            },
            child: Container(
              height: double.infinity,
              width: double.infinity,
              child: Icon(
                Icons.backspace,
                color: textColor,
              ),
            ));
        break;
      case VirtualKeyboardKeyAction.Shift:
        actionKey = Icon(Icons.arrow_upward, color: textColor);
        break;
      case VirtualKeyboardKeyAction.Space:
        actionKey = actionKey = Icon(Icons.space_bar, color: textColor);
        break;
      case VirtualKeyboardKeyAction.Return:
        actionKey = Icon(
          Icons.keyboard_return,
          color: textColor,
        );
        break;
      case VirtualKeyboardKeyAction.SwithLanguage:
        actionKey = GestureDetector(
            onTap: () {
              setState(() {
                customLayoutKeys!.switchLanguage();
              });
            },
            child: Container(
              height: double.infinity,
              width: double.infinity,
              child: Icon(
                Icons.language,
                color: textColor,
              ),
            ));
        break;
    }

    return Expanded(
      child: InkWell(
        onTap: () {
          if (key.action == VirtualKeyboardKeyAction.Shift) {
            if (!alwaysCaps) {
              setState(() {
                widget.isShiftEnabled = !widget.isShiftEnabled;
              });
            }
          }

          if (onKeyPress != null) {
            onKeyPress!(key);
          } else {
            _onKeyPress(key);
          }
        },
        child: Container(
          alignment: Alignment.center,
          height: height / customLayoutKeys!.activeLayout.length,
          child: actionKey,
        ),
      ),
    );
  }
}
