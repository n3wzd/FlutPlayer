import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/background_manager.dart';
import '../utils/stream_controller.dart';
import '../widgets/listtile.dart';
import '../widgets/button.dart';
import '../widgets/switch.dart';
import '../widgets/text.dart';
import '../widgets/text_field.dart';
import '../widgets/dialog.dart';
import '../models/color.dart';
import '../models/data.dart';

/// Tri-state for a per-group override: inherit the global setting, or force it.
enum _OverrideOption { inherit, show, hide }

_OverrideOption _toOption(bool? value) =>
    value == null ? _OverrideOption.inherit : (value ? _OverrideOption.show : _OverrideOption.hide);

bool? _fromOption(_OverrideOption option) => switch (option) {
  _OverrideOption.inherit => null,
  _OverrideOption.show => true,
  _OverrideOption.hide => false,
};

const List<Map> _overrideValueList = [
  {'value': _OverrideOption.inherit, 'label': 'Default'},
  {'value': _OverrideOption.show, 'label': 'Show'},
  {'value': _OverrideOption.hide, 'label': 'Hide'},
];

class BackgroundGroupPage extends StatefulWidget {
  const BackgroundGroupPage({super.key});

  @override
  State<BackgroundGroupPage> createState() => _BackgroundGroupPageState();
}

class _BackgroundGroupPageState extends State<BackgroundGroupPage> {
  List<BackgroundGroupData> get _groups => BackgroundManager.instance.groups;
  List<bool> _selectedList = [];
  int _selectedItemCount = 0;

  @override
  void initState() {
    super.initState();
    _resetSelection();
  }

  void _resetSelection() {
    _selectedList = List<bool>.filled(_groups.length, false, growable: true);
    _selectedItemCount = 0;
  }

  int _uniqueSelectedIndex() {
    for (int i = 0; i < _selectedList.length; i++) {
      if (_selectedList[i]) {
        return i;
      }
    }
    return 0;
  }

  List<int> _selectedIndexes() {
    final selected = <int>[];
    for (int i = 0; i < _selectedList.length; i++) {
      if (_selectedList[i]) {
        selected.add(i);
      }
    }
    return selected;
  }

  Future<void> _openDetail({String? originalLabel}) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) =>
            BackgroundGroupDetailPage(originalLabel: originalLabel),
      ),
    );
    setState(_resetSelection);
  }

  @override
  Widget build(BuildContext context) {
    final length = _groups.length;
    return Scaffold(
      backgroundColor: ColorPalette.black,
      appBar: AppBar(
        backgroundColor: ColorPalette.darkWine,
        automaticallyImplyLeading: false,
        actions: [
          ButtonFactory.iconButton(
            icon: const Icon(Icons.add_circle),
            iconColor: ColorPalette.lightGrey,
            onPressed: () => _openDetail(),
            outline: false,
          ),
          ButtonFactory.iconButton(
            icon: const Icon(Icons.change_circle),
            iconColor: ColorPalette.lightGrey,
            onPressed: _selectedItemCount == 1
                ? () => _openDetail(
                    originalLabel: _groups[_uniqueSelectedIndex()].label,
                  )
                : null,
            outline: false,
          ),
          ButtonFactory.iconButton(
            icon: const Icon(Icons.delete),
            iconColor: ColorPalette.lightGrey,
            onPressed: _selectedItemCount > 0
                ? () {
                    DialogFactory.choiceDialog(
                      context: context,
                      onOkPressed: () async {
                        final selected = _selectedIndexes();
                        for (int i = selected.length - 1; i >= 0; i--) {
                          await BackgroundManager.instance.deleteGroup(
                            _groups[selected[i]].label,
                          );
                        }
                        BackgroundManager.instance.updateBackgroundList();
                        setState(_resetSelection);
                      },
                      onCancelPressed: () {},
                      content: TextFactory.text('delete?'),
                    );
                  }
                : null,
            outline: false,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: length,
                itemBuilder: (context, index) => ListTileFactory.multiItem(
                  index: index,
                  text: _groups[index].label,
                  onTap: () {
                    setState(() {
                      _selectedList[index] = !_selectedList[index];
                      _selectedList[index]
                          ? _selectedItemCount++
                          : _selectedItemCount--;
                    });
                  },
                  selected: _selectedList[index],
                  trailing: SwitchFactory.normal(
                    value: _groups[index].active,
                    onChanged: (bool value) async {
                      await BackgroundManager.instance.setGroupActive(
                        _groups[index].label,
                        value,
                      );
                      setState(() {});
                    },
                  ),
                ),
              ),
            ),
            Container(
              alignment: Alignment.bottomCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ButtonFactory.textButton(
                    onPressed: () {
                      BackgroundManager.instance.updateBackgroundList();
                      AudioStreamController.emitBackgroundFileChanged();
                      Navigator.pop(context);
                    },
                    text: 'close',
                    fontSize: 24,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BackgroundGroupDetailPage extends StatefulWidget {
  const BackgroundGroupDetailPage({super.key, this.originalLabel});

  /// null = create a new group, otherwise edit the group with this label.
  final String? originalLabel;

  @override
  State<BackgroundGroupDetailPage> createState() =>
      _BackgroundGroupDetailPageState();
}

class _BackgroundGroupDetailPageState extends State<BackgroundGroupDetailPage> {
  final TextEditingController _labelController = TextEditingController();
  double _brightness = backgroundDefaultBrightness.toDouble();
  bool? _ncsLogo;
  bool? _visualizer;
  bool _active = true;
  List<String> _folders = [];

  bool get _isEdit => widget.originalLabel != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final group = BackgroundManager.instance.groups.firstWhere(
        (g) => g.label == widget.originalLabel,
        orElse: () => BackgroundGroupData(label: widget.originalLabel ?? ''),
      );
      _labelController.text = group.label;
      _brightness = group.brightness.toDouble();
      _ncsLogo = group.ncsLogo;
      _visualizer = group.visualizer;
      _active = group.active;
      _folders = List<String>.from(group.folders);
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _addFolder() async {
    final path = await FilePicker.getDirectoryPath();
    if (path != null && !_folders.contains(path)) {
      setState(() => _folders.add(path));
    }
  }

  Future<void> _save() async {
    final label = _labelController.text.trim();
    if (label.isEmpty) {
      await _showError('Label is empty.');
      return;
    }
    // Block duplicate labels (ignore self when editing).
    final duplicate = BackgroundManager.instance.groups.any(
      (g) => g.label == label && g.label != widget.originalLabel,
    );
    if (duplicate) {
      await _showError('Label already exists.');
      return;
    }

    final group = BackgroundGroupData(
      label: label,
      active: _active,
      brightness: _brightness.round(),
      ncsLogo: _ncsLogo,
      visualizer: _visualizer,
      folders: _folders,
    );

    if (_isEdit) {
      await BackgroundManager.instance.updateGroup(widget.originalLabel!, group);
    } else {
      await BackgroundManager.instance.addGroup(group);
    }
    BackgroundManager.instance.updateBackgroundList();
    AudioStreamController.emitBackgroundFileChanged();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _showError(String message) => DialogFactory.alertDialog(
    context: context,
    onPressed: () async => true,
    content: TextFactory.text(message),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.black,
      appBar: AppBar(
        backgroundColor: ColorPalette.darkWine,
        leading: ButtonFactory.iconButton(
          icon: const Icon(Icons.arrow_back),
          iconColor: ColorPalette.lightGrey,
          outline: false,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFactory.text('Label', fontSize: 18),
                  const SizedBox(height: 8),
                  TextFieldFactory.textField(controller: _labelController),
                ],
              ),
            ),
            ListTileFactory.contentSlider(
              title: 'Brightness',
              initialValue: _brightness,
              sliderMax: 100,
              sliderDivisions: 10,
              sliderShowLabel: true,
              onChanged: (value) => _brightness = value,
            ),
            ListTileFactory.contentDropDownMenu<_OverrideOption>(
              title: 'NCS Logo',
              initialSelection: _toOption(_ncsLogo),
              valueList: _overrideValueList,
              onSelected: (value) => _ncsLogo = _fromOption(value!),
            ),
            ListTileFactory.contentDropDownMenu<_OverrideOption>(
              title: 'Visualizer',
              initialSelection: _toOption(_visualizer),
              valueList: _overrideValueList,
              onSelected: (value) => _visualizer = _fromOption(value!),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextFactory.text('Folders', fontSize: 18),
                  ),
                  ButtonFactory.iconButton(
                    icon: const Icon(Icons.create_new_folder),
                    iconColor: ColorPalette.lightGrey,
                    onPressed: _addFolder,
                    outline: false,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _folders.length,
                itemBuilder: (context, index) => ListTileFactory.multiItem(
                  index: index,
                  text: _folders[index],
                  trailing: ButtonFactory.iconButton(
                    icon: const Icon(Icons.delete),
                    iconColor: ColorPalette.lightGrey,
                    onPressed: () => setState(() => _folders.removeAt(index)),
                    outline: false,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ButtonFactory.textButton(
                  onPressed: _save,
                  text: 'ok',
                  fontSize: 24,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
