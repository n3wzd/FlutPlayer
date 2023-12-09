import 'package:flutter/material.dart';

import './switch.dart';
import '../models/color.dart';
import './text.dart';
import './slider.dart';

class ListTileFactory {
  static const double listPadding = 16;

  static multiItem(
          {required int index,
          required String text,
          Key? key,
          VoidCallback? onTap,
          bool selected = false,
          Widget? trailing}) =>
      ListTile(
        key: key ?? UniqueKey(),
        title: SizedBox(
          height: 60,
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextFactory.text(
              text,
              fontSize: 18,
            ),
          ),
        ),
        minVerticalPadding: 0,
        onTap: onTap,
        selected: selected,
        selectedTileColor: ColorPalette.lightWine,
        tileColor: index % 2 == 1 ? ColorPalette.darkGrey : ColorPalette.black,
        hoverColor: ColorPalette.lightWine,
        trailing: trailing,
      );

  static title({required String text}) => ListTile(
        title:
            TextFactory.text(text, fontSize: 22, fontWeight: FontWeight.bold),
        tileColor: ColorPalette.darkWine,
        minVerticalPadding: listPadding,
      );

  static content(
          {required String title,
          String subtitle = '',
          VoidCallback? onTap,
          Widget? trailing}) =>
      ListTile(
        title: TextFactory.text(title, fontSize: 18),
        subtitle: TextFactory.text(subtitle,
            fontSize: 14, color: ColorPalette.grey, allowLineBreak: true),
        onTap: onTap,
        trailing: trailing,
        minVerticalPadding: listPadding,
      );

  static contentSwitch({
    required String title,
    String subtitle = '',
    bool initialValue = false,
    required void Function(bool) onChanged,
  }) {
    bool switchValue = initialValue;
    return content(
      title: title,
      subtitle: subtitle,
      trailing: StatefulBuilder(
        builder: (context, setState) => SwitchMaker.switchWidget(
          value: switchValue,
          onChanged: (bool value) {
            setState(() {
              onChanged(value);
              switchValue = value;
            });
          },
        ),
      ),
    );
  }

  static contentContainer(
          {required String title,
          String subtitle = '',
          required Widget child}) =>
      Container(
        padding: const EdgeInsets.all(listPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextFactory.text(title, fontSize: 18),
            (subtitle != '') ? const SizedBox(height: 2) : const SizedBox(),
            (subtitle != '')
                ? TextFactory.text(subtitle,
                    fontSize: 14,
                    color: ColorPalette.grey,
                    allowLineBreak: true)
                : const SizedBox(),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );

  static contentDropDownMenu<T>({
    required String title,
    String subtitle = '',
    required T initialSelection,
    required void Function(T?) onSelected,
    required List<Map> valueList,
  }) {
    T menuValue = initialSelection;
    return contentContainer(
      title: title,
      subtitle: subtitle,
      child: StatefulBuilder(
        builder: (context, setState) => DropdownButton<T>(
          value: menuValue,
          icon: const Icon(Icons.arrow_drop_down),
          onChanged: (T? value) {
            setState(() {
              if (value != null) {
                onSelected(value);
                menuValue = value;
              }
            });
          },
          isExpanded: true,
          dropdownColor: ColorPalette.darkGrey,
          items: List<DropdownMenuItem<T>>.generate(valueList.length, (index) {
            return DropdownMenuItem<T>(
                value: valueList[index]['value'],
                child:
                    TextFactory.text(valueList[index]['label'], fontSize: 18));
          }),
        ),
      ),
    );
  }

  static contentSlider({
    required String title,
    String subtitle = '',
    required double initialValue,
    required double sliderMax,
    double sliderMin = 0,
    int? sliderDivisions,
    bool sliderShowLabel = false,
    required void Function(double) onChanged,
    void Function(double)? onChangeEnd,
  }) {
    double sliderValue = initialValue;
    return contentContainer(
      title: title,
      subtitle: subtitle,
      child: StatefulBuilder(
        builder: (context, setState) => SliderFactory.slider(
          value: sliderValue,
          max: sliderMax,
          min: sliderMin,
          onChanged: (double value) {
            setState(() {
              onChanged(value);
              sliderValue = value;
            });
          },
          onChangeEnd: onChangeEnd,
          useOverlayColor: false,
          divisions: sliderDivisions,
          showLabel: sliderShowLabel,
        ),
      ),
    );
  }

  static contentRangeSlider({
    required String title,
    String subtitle = '',
    required RangeValues initialValues,
    required double sliderMax,
    double sliderMin = 0,
    int? sliderDivisions,
    bool sliderShowLabel = false,
    required void Function(RangeValues) onChanged,
    void Function(RangeValues)? onChangeEnd,
  }) {
    RangeValues sliderValues = initialValues;
    return contentContainer(
      title: title,
      subtitle: subtitle,
      child: StatefulBuilder(
        builder: (context, setState) => SliderFactory.rangeSlider(
          values: sliderValues,
          max: sliderMax,
          min: sliderMin,
          onChanged: (RangeValues values) {
            setState(() {
              onChanged(values);
              sliderValues = values;
            });
          },
          onChangeEnd: onChangeEnd,
          useOverlayColor: false,
          divisions: sliderDivisions,
          showLabel: sliderShowLabel,
        ),
      ),
    );
  }
}
